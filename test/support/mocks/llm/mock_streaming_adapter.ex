defmodule StartupGame.Mocks.LLM.MockStreamingAdapter do
  use GenServer

  @moduledoc """
  Mock LLM adapter that simulates streaming responses.
  """

  def generate_streaming_completion(_system_prompt, _user_prompt, llm_opts, handlers) do
    # Check if we should use a specific test mode
    test_mode = Map.get(llm_opts, :test_mode, :normal)

    case test_mode do
      :split_delimiter ->
        # Simulate streaming with the delimiter split across chunks
        simulate_split_delimiter_streaming(handlers)

      _ ->
        # Default behavior - normal streaming
        simulate_normal_streaming(handlers)
    end

    {:ok, "Streaming started"}
  end

  # Simulate normal streaming with the delimiter in a single chunk
  defp simulate_normal_streaming(handlers) do
    # First the narrative part
    Process.send_after(__MODULE__, {:simulate_delta, handlers, "This is the narrative part "}, 10)
    Process.send_after(__MODULE__, {:simulate_delta, handlers, "of the response. "}, 20)

    # Then the delimiter and JSON part
    Process.send_after(__MODULE__, {:simulate_delta, handlers, "---JSON DATA---\n"}, 30)
    Process.send_after(__MODULE__, {:simulate_delta, handlers, "{\n  \"id\": \"test_id\",\n"}, 40)

    Process.send_after(
      __MODULE__,
      {:simulate_delta, handlers, "  \"type\": \"test_type\"\n}"},
      50
    )

    # Complete message with full content
    Process.send_after(
      __MODULE__,
      {:simulate_complete, handlers,
       "This is the narrative part of the response. ---JSON DATA---\n{\n  \"id\": \"test_id\",\n  \"type\": \"test_type\"\n}"},
      60
    )
  end

  # Simulate streaming with the delimiter split across chunks
  defp simulate_split_delimiter_streaming(handlers) do
    # First the narrative part
    Process.send_after(
      __MODULE__,
      {:simulate_delta, handlers, "This is a narrative with a split"},
      10
    )

    Process.send_after(__MODULE__, {:simulate_delta, handlers, " delimiter ---"}, 20)
    Process.send_after(__MODULE__, {:simulate_delta, handlers, "JSON"}, 30)
    Process.send_after(__MODULE__, {:simulate_delta, handlers, " DATA---\n"}, 40)

    Process.send_after(
      __MODULE__,
      {:simulate_delta, handlers, "{\n  \"id\": \"split_test\",\n"},
      50
    )

    Process.send_after(
      __MODULE__,
      {:simulate_delta, handlers, "  \"type\": \"test_type\"\n}"},
      60
    )

    # Complete message with full content
    Process.send_after(
      __MODULE__,
      {:simulate_complete, handlers,
       "This is a narrative with a split delimiter ---JSON DATA---\n{\n  \"id\": \"split_test\",\n  \"type\": \"test_type\"\n}"},
      70
    )
  end

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_info({:simulate_delta, handlers, content}, state) do
    handlers.on_llm_new_delta.(nil, %LangChain.MessageDelta{
      content: content,
      status: :incomplete
    })

    {:noreply, state}
  end

  def handle_info({:simulate_complete, handlers, content}, state) do
    handlers.on_message_processed.(nil, %LangChain.Message{content: content, status: :complete})
    {:noreply, state}
  end
end
