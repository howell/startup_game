defmodule StartupGameWeb.GameLive.Handlers.StreamHandler do
  @moduledoc """
  Handles stream processing in the GameLive.Play module.
  Manages LLM streaming events, deltas, and completion.
  """

  use StartupGameWeb, :html

  alias StartupGame.StreamingService
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
  @spec handle_complete(socket(), {:llm_complete, stream_id(), StreamingService.stream_result()}) ::
          {:noreply, socket()}
  def handle_complete(socket, {:llm_complete, stream_id, result}) do
    if socket.assigns.stream_id == stream_id and socket.assigns.streaming do
      process_llm_result(socket, result)
    else
      # Not the stream we were waiting for, or not streaming anymore
      {:noreply, socket}
    end
  end

  # --- Private Helper Functions for handle_complete ---

  @spec process_llm_result(socket(), StreamingService.stream_result()) :: {:noreply, socket()}
  defp process_llm_result(socket, {:error, reason}) do
    on_error(socket, reason)
  end

  defp process_llm_result(socket, {:ok, result}) do
    game_id = socket.assigns.game_id

    next_socket = SocketAssignments.reset_streaming(socket)

    case {socket.assigns.streaming_type, result} do
      {:scenario, %{situation: _} = scenario} ->
        PlayHandler.finalize_scenario(next_socket, game_id, scenario)

      {:outcome, %{text: _} = outcome} ->
        PlayHandler.finalize_outcome(next_socket, game_id, outcome)

      {streaming_type, result} ->
        handle_unexpected_result(next_socket, streaming_type, result)
    end
  end

  @spec on_error(socket(), any()) :: {:noreply, socket()}
  defp on_error(socket, reason) do
    {:noreply,
     socket
     |> SocketAssignments.reset_streaming()
     |> Phoenix.LiveView.put_flash(:error, "Error: #{inspect(reason)}")}
  end

  @spec handle_unexpected_result(socket(), atom(), map()) :: {:noreply, socket()}
  defp handle_unexpected_result(socket, streaming_type, result) do
    on_error(
      socket,
      "Unexpected streaming result: #{inspect(streaming_type)}, #{inspect(result)}"
    )
  end

  @doc """
  Handles LLM error events.
  """
  @spec handle_error(socket(), {:llm_error, stream_id(), any()}) :: {:noreply, socket()}
  def handle_error(socket, {:llm_error, stream_id, error}) do
    if socket.assigns.stream_id == stream_id and socket.assigns.streaming do
      on_error(socket, error)
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
