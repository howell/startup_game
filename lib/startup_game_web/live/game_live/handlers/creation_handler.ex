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
          response: response,
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

    case GameService.create_and_start_game(
           name,
           response,
           user,
           provider
         ) do
      {:ok, %{game: game, game_state: game_state}} ->
        socket =
          socket
          |> SocketAssignments.assign_game_data(
            game,
            game_state,
            Games.list_game_rounds(game.id),
            Games.list_game_ownerships(game.id)
          )
          |> assign(:game_id, game.id)
          |> assign(:creation_stage, :playing)
          |> assign(:response, "")
          |> Phoenix.LiveView.put_flash(:info, "Started new venture: #{game.name}")

        # Update the URL to include the game ID without a full page navigation
        {:noreply, Phoenix.LiveView.push_patch(socket, to: ~p"/games/play/#{game.id}", replace: true)}

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
            Games.list_game_rounds(id),
            Games.list_game_ownerships(id)
          )
          |> assign(:game_id, id)
          |> assign(:response, "")
          |> assign(:creation_stage, :playing)

        # Recovery check for game in progress
        socket =
          if game_state.status == :in_progress do
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
    # No game_id parameter or empty parameter
    # If we already have a game loaded (i.e., not in name/description input stage),
    # keep that state; otherwise, stay in name input stage
    if socket.assigns.creation_stage in [:name_input, :description_input] or
         socket.assigns.game_id == nil do
      {:noreply, socket}
    else
      # We have a game but no game_id in URL - keep the game
      {:noreply, socket}
    end
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

    cond do
      # Case 1: Last round has a response but no outcome
      needs_outcome_recovery?(last_round) ->
        recover_missing_outcome(socket, game_id, last_round)

      # Case 2: All rounds complete but game is still in progress
      needs_scenario_recovery?(game.rounds) ->
        recover_next_scenario(socket, game_id)

      # Case 3: Game state is consistent, no recovery needed
      true ->
        socket
    end
  end

  @spec needs_outcome_recovery?(Round.t() | nil) :: boolean()
  defp needs_outcome_recovery?(nil), do: false
  defp needs_outcome_recovery?(round), do: round.response && !round.outcome

  @spec needs_scenario_recovery?([Round.t()]) :: boolean()
  defp needs_scenario_recovery?(rounds), do: Enum.all?(rounds, & &1.outcome)

  @spec recover_missing_outcome(socket(), String.t(), Round.t()) :: socket()
  defp recover_missing_outcome(socket, game_id, round) do
    # Subscribe to streaming topic for this game
    StreamingService.subscribe(game_id)

    # Start async recovery for missing outcome
    case GameService.recover_missing_outcome_async(game_id, round.response) do
      {:ok, stream_id} ->
        socket
        |> SocketAssignments.assign_streaming(stream_id, :outcome)
        |> Phoenix.LiveView.put_flash(:info, "Recovering your previous session...")

      {:error, reason} ->
        socket
        |> Phoenix.LiveView.put_flash(:error, "Error recovering game state: #{inspect(reason)}")
    end
  end

  @spec recover_next_scenario(socket(), String.t()) :: socket()
  defp recover_next_scenario(socket, game_id) do
    # Subscribe to streaming topic for this game
    StreamingService.subscribe(game_id)

    # Start async recovery for next scenario
    case GameService.recover_next_scenario_async(game_id) do
      {:ok, stream_id} ->
        socket
        |> SocketAssignments.assign_streaming(stream_id, :scenario)
        |> Phoenix.LiveView.put_flash(:info, "Generating next scenario...")

      {:error, reason} ->
        socket
        |> Phoenix.LiveView.put_flash(:error, "Error generating next scenario: #{inspect(reason)}")
    end
  end
end
