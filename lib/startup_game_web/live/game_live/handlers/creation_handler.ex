defmodule StartupGameWeb.GameLive.Handlers.CreationHandler do
  @moduledoc """
  Handles game creation flow in the GameLive.Play module.
  Manages the stages of game creation from name input to game initialization.
  """

  use StartupGameWeb, :html

  alias StartupGame.GameService
  alias StartupGame.Games
  alias StartupGame.Games.Round
  alias StartupGame.StreamingService
  alias StartupGameWeb.GameLive.Helpers.{SocketAssignments, ErrorHandler}
  alias StartupGameWeb.GameLive.Handlers.PlayHandler

  @type socket :: Phoenix.LiveView.Socket.t()

  @doc """
  Handles the name input stage of game creation.
  """
  @spec handle_name_input(socket(), String.t()) :: {:noreply, socket()}
  def handle_name_input(socket, response) when response != "" do
    # Store the company name and transition to description input
    socket =
      socket
      |> assign(:temp_name, response)
      |> assign(:creation_stage, :description_input)
      |> assign(:response, "")
      |> assign(:rounds, [
        %Round{
          id: "temp_name_prompt",
          situation: "What would you like to name your company?",
          player_input: response,
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        },
        %Round{
          id: "temp_description_prompt",
          situation: "Please provide a brief description of what #{response} does:",
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }
      ])

    {:noreply, socket}
  end

  @doc """
  Handles the description input stage of game creation.
  """
  @spec handle_description_input(socket(), String.t()) :: {:noreply, socket()}
  def handle_description_input(socket, response) when response != "" do
    # Create the game with the collected name and description
    user = socket.assigns.current_user
    name = socket.assigns.temp_name
    provider = socket.assigns.provider_preference
    # Get initial mode from assigns, default if not set yet (UI needs update later)
    initial_mode = socket.assigns[:initial_player_mode] || :responding

    updated_round = %Round{
      id: "temp_description_prompt",
      situation: "Please provide a brief description of what #{name} does:",
      player_input: response,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

    case GameService.create_game(
           name,
           # This is the description
           response,
           user,
           provider,
           # Empty attrs for now
           %{},
           initial_mode
         ) do
      {:ok, %{game: game}} ->
        socket =
          socket
          |> assign(:rounds, [updated_round])
          |> assign(:game_id, game.id)
          |> assign(:creation_stage, :playing)
          |> assign(:response, "")

        # Update the URL to include the game ID without a full page navigation
        {:noreply,
         Phoenix.LiveView.push_patch(socket, to: ~p"/games/play/#{game.id}", replace: true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        ErrorHandler.handle_game_error(socket, :game_creation, changeset)

      {:error, reason} ->
        ErrorHandler.handle_game_error(socket, :game_creation, reason)
    end
  end

  @doc """
  Handles loading an existing game when a game ID is provided in the URL.
  """
  @spec handle_existing_game(socket(), String.t()) :: {:noreply, socket()}
  def handle_existing_game(socket, id) do
    case GameService.load_game(id) do
      {:ok, %{game: game, game_state: game_state}} ->
        socket =
          socket
          |> SocketAssignments.assign_game_data(
            game,
            game_state,
            # keep the description round when transitioning from creating to playing
            socket.assigns.rounds ++ Games.list_game_rounds(id),
            Games.list_game_ownerships(id)
          )
          |> assign(:game_id, id)
          |> assign(:response, "")
          |> assign(:creation_stage, :playing)
          # Initialize player_mode from the loaded game
          |> assign(:player_mode, game.current_player_mode)

        # Recovery check for game in progress
        socket =
          if game_state.status == :in_progress && !socket.assigns.streaming do
            check_game_state_consistency(socket)
          else
            socket
          end

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply,
         socket
         |> Phoenix.LiveView.put_flash(:error, "Game not found")
         |> Phoenix.LiveView.redirect(to: ~p"/games")}
    end
  end

  @doc """
  Handles the case when no game ID is provided in the URL.
  """
  @spec handle_no_game_id(socket()) :: {:noreply, socket()}
  def handle_no_game_id(socket) do
    initial_round = %Round{
      id: "temp_name_prompt",
      situation: "What would you like to name your company?",
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

    {:noreply, assign(socket, :rounds, [initial_round])}
  end

  @doc """
  Handles initial player mode changes during game creation.
  """
  @spec handle_initial_mode_change(socket(), String.t()) :: {:noreply, socket()}
  def handle_initial_mode_change(socket, mode) do
    initial_mode = String.to_existing_atom(mode)

    {:noreply, assign(socket, :initial_player_mode, initial_mode)}
  end

  @doc """
  Handles provider preference changes during game creation.
  """
  @spec handle_provider_change(socket(), String.t()) :: {:noreply, socket()}
  def handle_provider_change(socket, provider) do
    # For game creation, just store the preference in the socket
    provider = String.to_existing_atom(provider)

    {:noreply,
     socket
     |> assign(:provider_preference, provider)
     |> Phoenix.LiveView.put_flash(:info, "Scenario provider set to #{provider}")}
  end

  @doc """
  Checks game state consistency and initiates recovery if needed.
  """
  @spec check_game_state_consistency(socket()) :: socket()
  def check_game_state_consistency(%{assigns: %{game: game, game_id: game_id}} = socket) do
    last_round = List.last(game.rounds)
    require Logger
    Logger.debug("Checking game state consistency for game #{game_id}")
    Logger.debug("Last round: #{inspect(last_round, pretty: true)}")
    Logger.debug("Needs outcome recovery? #{inspect(needs_outcome_recovery?(last_round))}")

    Logger.debug(
      "Needs scenario recovery? #{inspect(needs_scenario_recovery?(game, last_round))}"
    )

    cond do
      # Case 1: Last round has player_input but no outcome
      needs_outcome_recovery?(last_round) ->
        recover_missing_outcome(socket, game_id, last_round)

      # Case 2: Last round has outcome, game is in progress, and mode is :responding
      needs_scenario_recovery?(game, last_round) ->
        recover_next_scenario(socket, game_id)

      # Case 3: Game state is consistent (or player is in :acting mode), no recovery needed
      true ->
        socket
    end
  end

  @spec needs_outcome_recovery?(Round.t() | nil) :: boolean()
  defp needs_outcome_recovery?(nil), do: false
  # Use player_input field
  defp needs_outcome_recovery?(round), do: round.player_input && !round.outcome

  @spec needs_scenario_recovery?(StartupGame.Games.Game.t(), Round.t() | nil) :: boolean()
  # No rounds yet
  defp needs_scenario_recovery?(game, nil), do: game.current_player_mode == :responding

  defp needs_scenario_recovery?(game, last_round) do
    # Needs recovery if last round is complete, game is in progress, and mode is responding
    last_round.outcome && game.status == :in_progress && game.current_player_mode == :responding
  end

  @spec recover_missing_outcome(socket(), String.t(), Round.t()) :: socket()
  defp recover_missing_outcome(socket, game_id, round) do
    # Subscribe to streaming topic for this game
    StreamingService.subscribe(game_id)

    # Start async recovery for missing outcome using player_input
    case GameService.recover_missing_outcome_async(game_id, round.player_input) do
      {:ok, stream_id} ->
        socket
        # Set streaming type
        |> SocketAssignments.assign_streaming(stream_id, :outcome)
        |> Phoenix.LiveView.put_flash(:info, "Resuming game...")

      {:error, reason} ->
        socket
        |> Phoenix.LiveView.put_flash(:error, "Error resuming game: #{inspect(reason)}")
    end
  end

  @spec recover_next_scenario(socket(), String.t()) :: socket()
  defp recover_next_scenario(socket, game_id) do
    # Subscribe to streaming topic for this game
    StreamingService.subscribe(game_id)
    PlayHandler.request_next_scenario(socket) |> elem(1)
  end
end
