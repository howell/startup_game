defmodule StartupGameWeb.GameLive.Handlers.PlayHandler do
  @moduledoc """
  Handles gameplay actions in the GameLive.Play module.
  Manages user responses, game state transitions, and outcome processing.
  """

  use StartupGameWeb, :html

  require Logger

  alias StartupGame.GameService
  alias StartupGame.Games
  alias StartupGame.StreamingService
  alias StartupGameWeb.GameLive.Helpers.{SocketAssignments, ErrorHandler}
  alias StartupGameWeb.GameLive.Handlers.CreationHandler

  @type socket :: Phoenix.LiveView.Socket.t()

  @doc """
  Handles player responses during gameplay.
  """
  @spec handle_play_response(socket(), String.t()) :: {:noreply, socket()}
  def handle_play_response(socket, response) do
    game_id = socket.assigns.game.id

    StreamingService.subscribe(game_id)

    case GameService.process_player_input_async(game_id, response) do
      {:ok, stream_id, round} ->
        socket =
          socket
          |> SocketAssignments.assign_streaming(stream_id, :outcome)
          |> assign(:response, "")
          |> assign(:rounds, [round])

        {:noreply, socket}

      {:error, reason} ->
        StreamingService.unsubscribe(game_id)
        ErrorHandler.handle_game_error(socket, :response_processing, reason)
    end
  end

  @doc """
  Handles provider preference changes during gameplay.
  """
  @spec handle_provider_change(socket(), String.t()) :: {:noreply, socket()}
  def handle_provider_change(socket, provider_string) do
    game = socket.assigns.game
    provider_atom = String.to_existing_atom(provider_string)

    # Use update_game similar to toggle_visibility
    case StartupGame.Games.update_game(game, %{provider_preference: provider_string}) do
      {:ok, updated_game} ->
        # Also update the in-memory game_state's provider
        updated_game_state = %{socket.assigns.game_state | scenario_provider: provider_atom}

        {:noreply,
         socket
         |> assign(:game, updated_game)
         # Update game_state as well
         |> assign(:game_state, updated_game_state)
         |> Phoenix.LiveView.put_flash(:info, "Scenario provider updated to #{provider_string}")}

      {:error, reason} ->
        ErrorHandler.handle_game_error(socket, :provider_change, reason)
    end
  end

  @doc """
  Finalizes a streamed scenario.
  """
  @spec finalize_scenario(socket(), String.t(), map()) :: {:noreply, socket()}
  def finalize_scenario(socket, game_id, scenario) do
    case GameService.finalize_streamed_scenario(game_id, scenario) do
      {:ok, %{game: updated_game, game_state: updated_state}, new_round} ->
        # Append the new round to the existing list
        updated_rounds = socket.assigns.rounds ++ [new_round]

        socket =
          socket
          |> SocketAssignments.assign_game_data(
            updated_game,
            updated_state,
            # Use the appended list
            updated_rounds,
            # Ownerships shouldn't change on scenario generation
            socket.assigns.ownerships
          )

        {:noreply, socket}

      # Handle potential errors from finalize_streamed_scenario if necessary
      {:error, reason} ->
        ErrorHandler.handle_game_error(
          socket,
          :general,
          "Error finalizing scenario: #{inspect(reason)}"
        )
    end
  end

  @doc """
  Finalizes a streamed outcome. Does NOT start the next round.
  """
  @spec finalize_outcome(socket(), String.t(), map()) :: {:noreply, socket()}
  def finalize_outcome(socket, game_id, outcome) do
    # Finalize the outcome in the GameService
    case GameService.finalize_streamed_outcome(game_id, outcome) do
      {:ok, %{game: updated_game, game_state: updated_state}, updated_round} ->
        # Update the existing rounds list instead of reloading all
        current_rounds = socket.assigns.rounds
        round_index = Enum.find_index(current_rounds, fn r -> r.id == updated_round.id end)

        updated_rounds =
          if round_index do
            List.replace_at(current_rounds, round_index, updated_round)
          else
            [updated_round]
          end

        # Update the socket with the finalized outcome and game state
        socket =
          socket
          |> SocketAssignments.assign_game_data(
            updated_game,
            updated_state,
            # Use the surgically updated list
            updated_rounds,
            # Still need latest ownerships
            Games.list_game_ownerships(game_id)
          )

        if updated_state.status == :in_progress and
             updated_game.current_player_mode == :responding do
          request_next_scenario(socket)
        else
          {:noreply, socket}
        end

      {:error, reason} ->
        ErrorHandler.handle_game_error(
          socket,
          :general,
          "Error finalizing outcome: #{inspect(reason)}"
        )
    end
  end

  @spec request_next_scenario(socket()) :: {:noreply, socket()}
  @doc """
  Requests the next scenario from the GameService.
  """
  def request_next_scenario(socket) do
    game_id = socket.assigns.game_id

    # Request the next scenario from the GameService
    case GameService.request_next_scenario_async(game_id) do
      {:ok, stream_id} ->
        socket =
          socket
          |> SocketAssignments.assign_streaming(stream_id, :scenario)

        {:noreply, socket}

      {:error, reason} ->
        ErrorHandler.handle_game_error(socket, :general, reason)
    end
  end

  @doc """
  Handles switching the player mode.
  """
  @spec handle_switch_player_mode(socket(), String.t()) :: {:noreply, socket()}
  def handle_switch_player_mode(socket, player_mode) do
    game_id = socket.assigns.game.id

    case GameService.update_player_mode(game_id, player_mode) do
      {:ok, updated_game} ->
        require Logger
        Logger.debug("Updated game:\n\n#{inspect(updated_game, pretty: true)}")
        socket = assign(socket, game: updated_game)
        {:noreply, CreationHandler.check_game_state_consistency(socket)}

      {:error, reason} ->
        ErrorHandler.handle_game_error(socket, :general, reason)
    end
  end
end
