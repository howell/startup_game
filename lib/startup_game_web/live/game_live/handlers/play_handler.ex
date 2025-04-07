defmodule StartupGameWeb.GameLive.Handlers.PlayHandler do
  @moduledoc """
  Handles gameplay actions in the GameLive.Play module.
  Manages user responses, game state transitions, and outcome processing.
  """

  use StartupGameWeb, :html

  alias StartupGame.GameService
  alias StartupGame.Games
  alias StartupGame.StreamingService
  alias StartupGameWeb.GameLive.Helpers.{SocketAssignments, ErrorHandler}

  @type socket :: Phoenix.LiveView.Socket.t()

  @doc """
  Handles player responses during gameplay.
  """
  @spec handle_play_response(socket(), String.t()) :: {:noreply, socket()}
  def handle_play_response(socket, response) do
    game_id = socket.assigns.game_id

    # Create a temporary round entry for the response
    updated_round = Games.list_game_rounds(game_id) |> List.last() |> Map.put(:response, response)

    # Start the async response processing
    StreamingService.subscribe(game_id)

    case GameService.process_player_input_async(game_id, response) do
      {:ok, stream_id} ->
        socket =
          socket
          |> SocketAssignments.assign_streaming(stream_id, :outcome)
          |> assign(:response, "")
          |> assign(:rounds, [updated_round])

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
    {:ok, %{game: updated_game, game_state: updated_state}} =
      GameService.finalize_streamed_scenario(game_id, scenario)

    socket =
      socket
      |> SocketAssignments.assign_game_data(
        updated_game,
        updated_state,
        Games.list_game_rounds(game_id),
        socket.assigns.ownerships
      )

    {:noreply, socket}
  end

  @doc """
  Finalizes a streamed outcome. Does NOT start the next round.
  """
  @spec finalize_outcome(socket(), String.t(), map()) :: {:noreply, socket()}
  def finalize_outcome(socket, game_id, outcome) do
    # Finalize the outcome in the GameService
    case GameService.finalize_streamed_outcome(game_id, outcome) do
      {:ok, %{game: updated_game, game_state: updated_state}} ->
        # Update the socket with the finalized outcome and game state
        socket =
          socket
          |> SocketAssignments.assign_game_data(
            updated_game,
            updated_state,
            Games.list_game_rounds(game_id),
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
end
