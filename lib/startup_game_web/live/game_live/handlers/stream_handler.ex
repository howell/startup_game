defmodule StartupGameWeb.GameLive.Handlers.StreamHandler do
  @moduledoc """
  Handles stream processing in the GameLive.Play module.
  Manages LLM streaming events, deltas, and completion.
  """

  use StartupGameWeb, :html

  alias StartupGameWeb.GameLive.Handlers.PlayHandler
  alias StartupGameWeb.GameLive.Helpers.SocketAssignments

  @type socket :: Phoenix.LiveView.Socket.t()
  @type stream_id :: String.t()
  @type streaming_type :: :outcome | :scenario

  @doc """
  Handles LLM delta events during streaming.
  """
  @spec handle_delta(socket(), {:llm_delta, stream_id(), any(), String.t()}) :: {:noreply, socket()}
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
  @spec handle_complete(socket(), {:llm_complete, stream_id(), {:ok, map()}}) :: {:noreply, socket()}
  def handle_complete(socket, {:llm_complete, stream_id, {:ok, result}}) do
    if socket.assigns.stream_id == stream_id and socket.assigns.streaming do
      game_id = socket.assigns.game_id

      # Process the completed response based on what we're streaming
      # (Either a scenario or an outcome)
      case {socket.assigns.streaming_type, result} do
        {:scenario, %{situation: _} = scenario} ->
          PlayHandler.finalize_scenario(socket, game_id, scenario)

        {:outcome, %{text: _} = outcome} ->
          PlayHandler.finalize_outcome(socket, game_id, outcome)

        # Handle unexpected result types
        {streaming_type, result} ->
          {:noreply,
           socket
           |> Phoenix.LiveView.put_flash(
             :error,
             "Unexpected streaming result: #{inspect(streaming_type)}, #{inspect(result)}"
           )
           |> SocketAssignments.reset_streaming()}
      end
    else
      {:noreply, socket}
    end
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
