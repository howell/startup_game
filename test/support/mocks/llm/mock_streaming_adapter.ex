defmodule StartupGame.Mocks.LLM.MockStreamingAdapter do
  use GenServer

  @behaviour StartupGame.Engine.LLM.Adapter

  @moduledoc """
  Mock LLM adapter that simulates streaming responses.

  ## Test Modes

  The adapter supports several test modes that can be specified in `llm_opts`:

  - `:normal` - Normal streaming with completion (default)
  - `:split_delimiter` - Simulates the delimiter being split across chunks
  - `:partial` - Sends delta(s) but never completes
  - `:error` - Triggers an error, optionally after some deltas
  - `:immediate_error` - Immediately returns an error without streaming
  - `:custom` - Uses custom deltas and completion from options

  ## Custom Streaming Data

  You can provide custom streaming data via the `llm_opts` map:

  ```elixir
  llm_opts = %{
    test_mode: :normal,
    custom_deltas: ["First chunk", "Second chunk"],
    custom_completion: "Full content",
    custom_error: "Custom error message",
    delay_between_deltas: 20 # milliseconds
  }
  ```

  ## Examples

  ```elixir
  # Simulate normal streaming
  MockStreamingAdapter.generate_streaming_completion(system_prompt, user_prompt, %{}, handlers)

  # Simulate partial streaming (never completes)
  MockStreamingAdapter.generate_streaming_completion(
    system_prompt,
    user_prompt,
    %{test_mode: :partial},
    handlers
  )

  # Simulate error after some deltas
  MockStreamingAdapter.generate_streaming_completion(
    system_prompt,
    user_prompt,
    %{
      test_mode: :error,
      custom_deltas: ["Some output before error"],
      custom_error: "Simulated API failure"
    },
    handlers
  )

  # Simulate immediate error (no streaming)
  MockStreamingAdapter.generate_streaming_completion(
    system_prompt,
    user_prompt,
    %{
      test_mode: :immediate_error,
      custom_error: "API connection failure"
    },
    handlers
  )

  # Custom streaming with specific data
  MockStreamingAdapter.generate_streaming_completion(
    system_prompt,
    user_prompt,
    %{
      test_mode: :custom,
      custom_deltas: ["First part", "Second part", "Third part"],
      custom_completion: "Full response with all parts",
      delay_between_deltas: 50
    },
    handlers
  )
  ```
  """

  @type test_mode :: :normal | :split_delimiter | :partial | :error | :immediate_error | :custom
  @type llm_opts :: %{
          optional(:test_mode) => test_mode(),
          optional(:custom_deltas) => [String.t()],
          optional(:custom_completion) => String.t(),
          optional(:custom_error) => String.t(),
          optional(:delay_between_deltas) => non_neg_integer()
        }

  def generate_completion(_system_prompt, _user_prompt, _llm_opts) do
    {:error, "Not implemented"}
  end

  @spec generate_streaming_completion(
          String.t(),
          String.t(),
          llm_opts(),
          map()
        ) :: {:ok, String.t()} | {:error, String.t()}
  def generate_streaming_completion(_system_prompt, _user_prompt, llm_opts, handlers) do
    # Check if we should use a specific test mode
    test_mode = Map.get(llm_opts, :test_mode, :normal)

    # Extract the stream_id from the handlers if present
    # This is used to properly simulate the error path
    stream_id = extract_stream_id_from_handlers(handlers)
    llm_opts = Map.put(llm_opts, :stream_id, stream_id)

    case test_mode do
      :immediate_error ->
        # Immediately return an error (no streaming)
        custom_error = Map.get(llm_opts, :custom_error, "Immediate mock error")
        {:error, custom_error}

      :split_delimiter ->
        # Simulate streaming with the delimiter split across chunks
        simulate_split_delimiter_streaming(handlers)

      :partial ->
        # Simulate partial streaming without completion
        simulate_partial_streaming(handlers, llm_opts)

      :error ->
        # Simulate error during streaming
        simulate_error_streaming(handlers, llm_opts)

      :custom ->
        # Use custom deltas and completion from options
        simulate_custom_streaming(handlers, llm_opts)

      _ ->
        # Default behavior - normal streaming
        simulate_normal_streaming(handlers)
    end

    # Only return success if we didn't immediately error out
    if test_mode != :immediate_error do
      {:ok, "Streaming started"}
    end
  end

  # Try to extract the stream_id from the handlers by analyzing the callback functions
  defp extract_stream_id_from_handlers(handlers) do
    # Look at any of the handler functions to try to extract the stream_id pattern
    # that might be captured in closures
    with handlers_string when is_binary(handlers_string) <- inspect(handlers),
         [_, stream_id] <-
           Regex.run(~r/stream_delta", "?(stream_[a-f0-9-]+)"?, /, handlers_string) do
      stream_id
    else
      _ -> nil
    end
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

  # Simulate partial streaming that never completes
  defp simulate_partial_streaming(handlers, llm_opts) do
    custom_deltas =
      Map.get(llm_opts, :custom_deltas, ["Partial streaming ", "that never completes."])

    delay_between_deltas = Map.get(llm_opts, :delay_between_deltas, 20)

    # Send custom deltas with increasing delays
    Enum.with_index(custom_deltas)
    |> Enum.each(fn {delta, index} ->
      Process.send_after(
        __MODULE__,
        {:simulate_delta, handlers, delta},
        (index + 1) * delay_between_deltas
      )
    end)

    # No completion message is sent
  end

  # Simulate streaming that results in an error
  defp simulate_error_streaming(handlers, llm_opts) do
    custom_deltas = Map.get(llm_opts, :custom_deltas, ["Starting stream ", "before error..."])
    custom_error = Map.get(llm_opts, :custom_error, "Simulated error occurred")
    delay_between_deltas = Map.get(llm_opts, :delay_between_deltas, 20)
    stream_id = Map.get(llm_opts, :stream_id, nil)

    # Send some deltas before the error
    Enum.with_index(custom_deltas)
    |> Enum.each(fn {delta, index} ->
      Process.send_after(
        __MODULE__,
        {:simulate_delta, handlers, delta},
        (index + 1) * delay_between_deltas
      )
    end)

    # Send the error to the GenServer directly after deltas
    # This mirrors how LLMStreamService expects errors to be handled
    delta_count = length(custom_deltas)

    # Get a reference to the LLMStreamService module, which should be available in the handlers
    # or default to the module itself
    target_module = Module.concat(["StartupGame", "Engine", "LLM", "LLMStreamService"])

    Process.send_after(
      __MODULE__,
      {:trigger_error, target_module, stream_id, custom_error},
      (delta_count + 1) * delay_between_deltas
    )
  end

  # Simulate streaming with custom deltas and completion from options
  defp simulate_custom_streaming(handlers, llm_opts) do
    custom_deltas = Map.get(llm_opts, :custom_deltas, ["Custom ", "streaming ", "data"])
    custom_completion = Map.get(llm_opts, :custom_completion, "Custom streaming data")
    delay_between_deltas = Map.get(llm_opts, :delay_between_deltas, 20)

    # Send custom deltas with increasing delays
    Enum.with_index(custom_deltas)
    |> Enum.each(fn {delta, index} ->
      Process.send_after(
        __MODULE__,
        {:simulate_delta, handlers, delta},
        (index + 1) * delay_between_deltas
      )
    end)

    # Send completion after deltas
    delta_count = length(custom_deltas)

    Process.send_after(
      __MODULE__,
      {:simulate_complete, handlers, custom_completion},
      (delta_count + 1) * delay_between_deltas
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

  def handle_info({:trigger_error, target_module, stream_id, error}, state) do
    # Send the error directly to the LLMStreamService if stream_id is provided
    if stream_id do
      GenServer.cast(target_module, {:stream_error, stream_id, error})
    else
      # Log the error if we can't directly send it
      require Logger
      Logger.error("Mock Streaming Error: #{inspect(error)}")
    end

    {:noreply, state}
  end
end
