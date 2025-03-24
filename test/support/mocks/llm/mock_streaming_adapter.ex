defmodule StartupGame.Mocks.LLM.MockStreamingAdapter do
  use GenServer

  @moduledoc """
  Mock LLM adapter that simulates streaming responses.
  """

  def generate_streaming_completion(_system_prompt, _user_prompt, _llm_opts, handlers) do
    # Simulate streaming by sending deltas
    Process.send_after(__MODULE__, {:simulate_delta, handlers, "First part of "}, 10)
    Process.send_after(__MODULE__, {:simulate_delta, handlers, "the response"}, 20)

    Process.send_after(
      __MODULE__,
      {:simulate_complete, handlers, "First part of the response"},
      30
    )

    {:ok, "Streaming started"}
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
