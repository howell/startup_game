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
  def handle_play_response(socket, response) when response != "" do
    game_id = socket.assigns.game_id

    # Create a temporary round entry for the response
    updated_round = Games.list_game_rounds(game_id) |> List.last() |> Map.put(:response, response)

    # Start the async response processing
    case GameService.process_response_async(game_id, response) do
      {:ok, stream_id} ->
        # Subscribe to the streaming topic
        StreamingService.subscribe(game_id)

        socket =
          socket
          |> SocketAssignments.assign_streaming(stream_id, :outcome)
          |> assign(:response, "")
          |> assign(:rounds, [updated_round])

        {:noreply, socket}

      {:error, reason} ->
        ErrorHandler.handle_game_error(socket, :response_processing, reason)
    end
  end

  @doc """
  Handles provider preference changes during gameplay.
  """
  @spec handle_provider_change(socket(), String.t()) :: {:noreply, socket()}
  def handle_provider_change(socket, provider) do
    game = socket.assigns.game

    case StartupGame.Games.update_provider_preference(game, provider) do
      {:ok, updated_game} ->
        {:noreply,
         socket
         |> assign(:game, updated_game)
         |> Phoenix.LiveView.put_flash(:info, "Scenario provider updated to #{provider}")}

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
      |> SocketAssignments.reset_streaming()

    {:noreply, socket}
  end

  @doc """
  Finalizes a streamed outcome and potentially starts the next round.
  """
  @spec finalize_outcome(socket(), String.t(), map()) :: {:noreply, socket()}
  def finalize_outcome(socket, game_id, outcome) do
    # We received an outcome - finalize it first
    {:ok, %{game: updated_game, game_state: updated_state}} =
      GameService.finalize_streamed_outcome(game_id, outcome)

    # Update the socket with the finalized outcome
    socket =
      socket
      |> SocketAssignments.assign_game_data(
        updated_game,
        updated_state,
        Games.list_game_rounds(game_id),
        Games.list_game_ownerships(game_id)
      )
      |> SocketAssignments.reset_streaming()

    # Only start the next round if the game is still in progress
    if updated_state.status == :in_progress do
      # Start streaming the next scenario
      case GameService.start_next_round_async(updated_game, updated_state) do
        {:ok, new_stream_id} ->
          # Ensure we're subscribed to the streaming topic
          StreamingService.subscribe(game_id)

          # Update socket for the new streaming scenario
          socket =
            socket
            |> SocketAssignments.assign_streaming(new_stream_id, :scenario)

          {:noreply, socket}

        {:error, reason} ->
          ErrorHandler.handle_game_error(socket, :general, "Error starting next round: #{inspect(reason)}")
      end
    else
      # Game is over, no need to start next round
      {:noreply, socket}
    end
  end
end
