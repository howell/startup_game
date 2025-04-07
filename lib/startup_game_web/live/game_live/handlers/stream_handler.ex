defmodule StartupGameWeb.GameLive.Handlers.StreamHandler do
  @moduledoc """
  Handles stream processing in the GameLive.Play module.
  Manages LLM streaming events, deltas, and completion.
  """

  use StartupGameWeb, :html

  # Added
  alias StartupGame.GameService
  alias StartupGameWeb.GameLive.Handlers.PlayHandler
  alias StartupGameWeb.GameLive.Helpers.SocketAssignments

  @type socket :: Phoenix.LiveView.Socket.t()
  @type stream_id :: String.t()
  @type streaming_type :: :outcome | :scenario

  @doc """
  Handles LLM delta events during streaming.
  """
  @spec handle_delta(socket(), {:llm_delta, stream_id(), any(), String.t()}) ::
          {:noreply, socket()}
  def handle_delta(socket, {:llm_delta, stream_id, _delta, display_content}) do
    if socket.assigns.stream_id == stream_id and socket.assigns.streaming do
      # Update the display content (narrative part only)
      socket =
        socket
        |> assign(:partial_content, display_content)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @doc """
  Handles LLM completion events.
  """
  @spec handle_complete(socket(), {:llm_complete, stream_id(), {:ok, map()}}) ::
          {:noreply, socket()}
  def handle_complete(socket, {:llm_complete, stream_id, {:ok, result}}) do
    if socket.assigns.stream_id == stream_id and socket.assigns.streaming do
      process_llm_result(socket, result)
    else
      # Not the stream we were waiting for, or not streaming anymore
      {:noreply, socket}
    end
  end

  # --- Private Helper Functions for handle_complete ---

  @spec process_llm_result(socket(), map()) :: {:noreply, socket()}
  defp process_llm_result(socket, result) do
    game_id = socket.assigns.game_id

    next_socket = SocketAssignments.reset_streaming(socket)

    case {socket.assigns.streaming_type, result} do
      {:scenario, %{situation: _} = scenario} ->
        handle_scenario_completion(next_socket, game_id, scenario)

      {:outcome, %{text: _} = outcome} ->
        handle_outcome_completion(next_socket, game_id, outcome)

      # Handle unexpected result types
      {streaming_type, result} ->
        handle_unexpected_result(next_socket, streaming_type, result)
    end
  end

  @spec handle_scenario_completion(socket(), String.t(), map()) :: {:noreply, socket()}
  defp handle_scenario_completion(socket, game_id, scenario) do
    # Finalize the scenario (updates assigns, creates DB round)
    {:noreply, socket_after_scenario} =
      PlayHandler.finalize_scenario(socket, game_id, scenario)

    # Ensure player mode is :responding and persist it
    socket_with_mode = assign(socket_after_scenario, :player_mode, :responding)
    GameService.update_player_mode(game_id, "responding")

    {:noreply, socket_with_mode}
  end

  @spec handle_outcome_completion(socket(), String.t(), map()) :: {:noreply, socket()}
  defp handle_outcome_completion(socket, game_id, outcome) do
    # Finalize the outcome (updates assigns, saves round result)
    {:noreply, socket_after_outcome} =
      PlayHandler.finalize_outcome(socket, game_id, outcome)

    # Check player mode to decide next step
    if socket_after_outcome.assigns.player_mode == :responding do
      # If responding, automatically request the next scenario

      case GameService.request_next_scenario_async(game_id) do
        {:ok, stream_id} ->
          {:noreply,
           SocketAssignments.assign_streaming(socket_after_outcome, stream_id, :scenario)}

        {:error, reason} ->
          # Handle error in requesting next scenario
          {:noreply,
           Phoenix.LiveView.put_flash(socket_after_outcome, :error, "Error: #{inspect(reason)}")}
      end
    else
      # If acting, do nothing further, player stays in control
      {:noreply, socket_after_outcome}
    end
  end

  @spec handle_unexpected_result(socket(), atom(), map()) :: {:noreply, socket()}
  defp handle_unexpected_result(socket, streaming_type, result) do
    {:noreply,
     socket
     |> Phoenix.LiveView.put_flash(
       :error,
       "Unexpected streaming result: #{inspect(streaming_type)}, #{inspect(result)}"
     )
     |> SocketAssignments.reset_streaming()}
  end

  @doc """
  Handles LLM error events.
  """
  @spec handle_error(socket(), {:llm_error, stream_id(), any()}) :: {:noreply, socket()}
  def handle_error(socket, {:llm_error, stream_id, error}) do
    if socket.assigns.stream_id == stream_id and socket.assigns.streaming do
      socket =
        socket
        |> SocketAssignments.reset_streaming()
        |> Phoenix.LiveView.put_flash(:error, "Error: #{error}")

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @doc """
  Handles task completion messages.
  """
  @spec handle_task_complete(socket(), any()) :: {:noreply, socket()}
  def handle_task_complete(socket, _result) do
    # Ignore Task completion messages
    {:noreply, socket}
  end

  @doc """
  Handles task process DOWN messages.
  """
  @spec handle_task_down(socket(), any()) :: {:noreply, socket()}
  def handle_task_down(socket, _reason) do
    # Ignore Task process DOWN messages
    {:noreply, socket}
  end
end
