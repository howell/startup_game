# Mock adapter that doesn't hit the real API
defmodule StartupGame.Engine.LLM.LLMStreamServiceTest do
  use StartupGame.DataCase, async: true

  alias StartupGame.Engine.LLM.LLMStreamService
  alias StartupGame.Engine.LLM.JSONResponseParser
  alias StartupGame.Mocks.LLM.MockStreamingAdapter
  alias StartupGame.GameService
  alias StartupGame.GamesFixtures

  # Mock provider module for testing
  defmodule MockProvider do
    def llm_adapter, do: MockStreamingAdapter
    def llm_options, do: %{model: "test-model"}
    def scenario_system_prompt, do: "You are a scenario generator"
    def outcome_system_prompt, do: "You are an outcome generator"

    def create_scenario_prompt(_game_state, _current_scenario_id) do
      "Generate a scenario"
    end

    def create_outcome_prompt(_game_state, _scenario, _response_text) do
      "Generate an outcome"
    end
  end

  # Mock provider for split delimiter testing
  defmodule SplitDelimiterProvider do
    def llm_adapter, do: MockStreamingAdapter
    def llm_options, do: %{model: "test-model", test_mode: :split_delimiter}
    def scenario_system_prompt, do: "You are a scenario generator"
    def outcome_system_prompt, do: "You are an outcome generator"

    def create_scenario_prompt(_game_state, _current_scenario_id) do
      "Generate a scenario with split delimiter"
    end

    def create_outcome_prompt(_game_state, _scenario, _response_text) do
      "Generate an outcome with split delimiter"
    end
  end

  setup do
    # Subscribe to PubSub for testing
    game_id = "test-game-#{:rand.uniform(1000)}"
    StartupGameWeb.Endpoint.subscribe("llm_stream:#{game_id}")

    # Make sure meck is cleaned up after each test
    on_exit(fn ->
      :meck.unload()
    end)

    %{game_id: game_id}
  end

  describe "generate_scenario/4" do
    test "returns a stream_id and initializes streaming", %{game_id: game_id} do
      game_state = %{cash_on_hand: 10_000}
      current_scenario_id = nil

      # Mock the JSONResponseParser first
      :meck.new(JSONResponseParser, [:passthrough])

      :meck.expect(JSONResponseParser, :parse_scenario, fn _content ->
        {:ok, %{situation: "Test scenario", options: ["Option 1", "Option 2"]}}
      end)

      # Start the test process to handle the messages
      {:ok, _test_pid} = MockStreamingAdapter.start_link()

      {:ok, stream_id} =
        LLMStreamService.generate_scenario(
          game_id,
          game_state,
          current_scenario_id,
          MockProvider
        )

      # Assert that we got a stream_id
      assert is_binary(stream_id)
      assert String.starts_with?(stream_id, "stream_")

      # Wait for the narrative part deltas
      assert_receive %{
                       event: "llm_delta",
                       payload:
                         {:llm_delta, ^stream_id, "This is the narrative part ",
                          "This is the narrative part "}
                     },
                     100

      assert_receive %{
                       event: "llm_delta",
                       payload:
                         {:llm_delta, ^stream_id, "of the response. ",
                          "This is the narrative part of the response. "}
                     },
                     100

      # The JSON part should not be broadcast as a delta
      refute_receive %{
                       event: "llm_delta",
                       payload: {:llm_delta, ^stream_id, "---JSON DATA---\n", _}
                     },
                     100

      # Wait for completion
      assert_receive %{
                       event: "llm_complete",
                       payload: {:llm_complete, ^stream_id, {:ok, %{situation: "Test scenario"}}}
                     },
                     100

      # Clean up mocks
      # :meck.unload(StartupGame.Engine.LLM.AnthropicAdapter)
      :meck.unload(JSONResponseParser)
    end

    test "handles delimiter split across multiple chunks", %{game_id: game_id} do
      game_state = %{cash_on_hand: 10_000}
      current_scenario_id = nil

      # Mock the JSONResponseParser first
      :meck.new(JSONResponseParser, [:passthrough])

      :meck.expect(JSONResponseParser, :parse_scenario, fn _content ->
        {:ok,
         %{
           situation: "This is a narrative with a split delimiter",
           options: ["Option 1", "Option 2"]
         }}
      end)

      # Start the test process to handle the messages
      {:ok, _test_pid} = MockStreamingAdapter.start_link()

      {:ok, stream_id} =
        LLMStreamService.generate_scenario(
          game_id,
          game_state,
          current_scenario_id,
          SplitDelimiterProvider
        )

      # Assert that we got a stream_id
      assert is_binary(stream_id)
      assert String.starts_with?(stream_id, "stream_")

      # Wait for the narrative part deltas
      assert_receive %{
                       event: "llm_delta",
                       payload: {:llm_delta, ^stream_id, "This is a narrative with a split", _}
                     },
                     100

      assert_receive %{
                       event: "llm_delta",
                       payload: {:llm_delta, ^stream_id, " delimiter ", _}
                     },
                     100

      # The JSON part should not be broadcast as a delta
      refute_receive %{
                       event: "llm_delta",
                       payload: {:llm_delta, ^stream_id, "---", _}
                     },
                     20

      refute_receive %{
                       event: "llm_delta",
                       payload: {:llm_delta, ^stream_id, "JSON", _}
                     },
                     20

      refute_receive %{
                       event: "llm_delta",
                       payload: {:llm_delta, ^stream_id, " DATA---\n", _}
                     },
                     20

      # Wait for completion
      assert_receive %{
                       event: "llm_complete",
                       payload: {:llm_complete, ^stream_id, {:ok, _scenario}}
                     },
                     20

      # Clean up mocks
      :meck.unload(JSONResponseParser)
    end

    @tag :skip
    @tag :external_api
    test "integration test with real API (skipped by default)", %{game_id: game_id} do
      # This test actually hits the Anthropic API and should be skipped by default
      # To run this test, use: mix test --include external_api

      game = GamesFixtures.game_fixture(%{cash_on_hand: 10_000, start?: false})
      {:ok, %{game_state: game_state}} = GameService.load_game(game.id)

      {:ok, stream_id} =
        LLMStreamService.generate_scenario(
          game_id,
          game_state,
          nil,
          StartupGame.Engine.LLMScenarioProvider
        )

      # Assert that we got a stream_id
      assert is_binary(stream_id)

      # Wait for deltas (may take some time with real API)
      assert_receive %{
                       event: "llm_delta",
                       payload: {:llm_delta, ^stream_id, _delta_content, _full_content}
                     },
                     3_000

      # Wait for completion (may take some time with real API)
      assert_receive %{
                       event: "llm_complete",
                       payload: {:llm_complete, ^stream_id, {:ok, _scenario}}
                     },
                     10_000
    end
  end

  describe "generate_outcome/5" do
    test "returns a stream_id and initializes streaming", %{game_id: game_id} do
      game_state = %{cash_on_hand: 10_000}
      scenario = %{situation: "Test scenario", options: ["Option 1", "Option 2"]}
      response_text = "Option 1"

      # Mock the JSONResponseParser first
      :meck.new(JSONResponseParser, [:passthrough])

      :meck.expect(JSONResponseParser, :parse_outcome, fn _content ->
        {:ok, %{text: "Test outcome", cash_change: 1000}}
      end)

      {:ok, _test_pid} = MockStreamingAdapter.start_link()

      # Call the function
      {:ok, stream_id} =
        LLMStreamService.generate_outcome(
          game_id,
          game_state,
          scenario,
          response_text,
          MockProvider
        )

      # Assert that we got a stream_id
      assert is_binary(stream_id)
      assert String.starts_with?(stream_id, "stream_")

      # Wait for the narrative part deltas
      assert_receive %{
                       event: "llm_delta",
                       payload:
                         {:llm_delta, ^stream_id, "This is the narrative part ",
                          "This is the narrative part "}
                     },
                     100

      assert_receive %{
                       event: "llm_delta",
                       payload:
                         {:llm_delta, ^stream_id, "of the response. ",
                          "This is the narrative part of the response. "}
                     },
                     100

      # The JSON part should not be broadcast as a delta
      refute_receive %{
                       event: "llm_delta",
                       payload: {:llm_delta, ^stream_id, "---JSON DATA---\n", _}
                     },
                     100

      # Wait for completion
      assert_receive %{
                       event: "llm_complete",
                       payload: {:llm_complete, ^stream_id, {:ok, %{text: "Test outcome"}}}
                     },
                     100

      # Clean up mocks
      :meck.unload(JSONResponseParser)
    end
  end

  describe "error handling" do
    test "handles API errors gracefully", %{game_id: game_id} do
      game_state = %{cash_on_hand: 10_000}
      current_scenario_id = nil

      # Mock the AnthropicAdapter to return an error
      :meck.new(MockStreamingAdapter, [:passthrough])

      :meck.expect(
        MockStreamingAdapter,
        :generate_streaming_completion,
        fn _system_prompt, _user_prompt, _llm_opts, _handlers ->
          {:error, "API error: rate limit exceeded"}
        end
      )

      # Call the function
      {:ok, stream_id} =
        LLMStreamService.generate_scenario(
          game_id,
          game_state,
          current_scenario_id,
          MockProvider
        )

      # Wait for the error message
      assert_receive %{
                       event: "llm_error",
                       payload: {:llm_error, ^stream_id, "API error: rate limit exceeded"}
                     },
                     100

      # Clean up mock
      :meck.unload(MockStreamingAdapter)
    end

    test "handles exceptions during API calls", %{game_id: game_id} do
      game_state = %{cash_on_hand: 10_000}
      current_scenario_id = nil

      # Mock the AnthropicAdapter to raise an exception
      :meck.new(MockStreamingAdapter, [:passthrough])

      :meck.expect(
        MockStreamingAdapter,
        :generate_streaming_completion,
        fn _system_prompt, _user_prompt, _llm_opts, _handlers ->
          raise "Connection error"
        end
      )

      # Call the function
      {:ok, stream_id} =
        LLMStreamService.generate_scenario(
          game_id,
          game_state,
          current_scenario_id,
          MockProvider
        )

      # Wait for the error message
      assert_receive %{event: "llm_error", payload: {:llm_error, ^stream_id, error_message}}, 100
      assert error_message =~ "LLM API error"
      assert error_message =~ "Connection error"

      # Clean up mock
      :meck.unload(MockStreamingAdapter)
    end

    test "handles JSON parsing errors", %{game_id: game_id} do
      game_state = %{cash_on_hand: 10_000}
      current_scenario_id = nil

      # Start the test process to handle the messages
      {:ok, test_pid} = MockStreamingAdapter.start_link()

      # Mock the AnthropicAdapter
      :meck.new(MockStreamingAdapter, [:passthrough])

      :meck.expect(
        MockStreamingAdapter,
        :generate_streaming_completion,
        fn _system_prompt, _user_prompt, _llm_opts, handlers ->
          # Simulate streaming with invalid JSON
          Process.send_after(test_pid, {:simulate_complete, handlers, "Invalid JSON content"}, 10)
          {:ok, "Streaming started"}
        end
      )

      # Mock the JSONResponseParser to return an error
      :meck.new(JSONResponseParser, [:passthrough])

      :meck.expect(JSONResponseParser, :parse_scenario, fn _content ->
        {:error, "Invalid JSON format"}
      end)

      # Call the function
      {:ok, stream_id} =
        LLMStreamService.generate_scenario(
          game_id,
          game_state,
          current_scenario_id,
          MockProvider
        )

      # Wait for completion with error
      assert_receive %{
                       event: "llm_complete",
                       payload: {:llm_complete, ^stream_id, {:error, error_message}}
                     },
                     100

      assert error_message =~ "Failed to parse scenario"

      # Clean up mocks
      :meck.unload(MockStreamingAdapter)
      :meck.unload(JSONResponseParser)
    end
  end

  describe "process_delta_parts/4" do
    test "handles unambiguously narrative parts", _ do
      r = LLMStreamService.process_delta_parts("Hello!", false, "")
      assert {"Hello!", false, ""} == r
    end

    test "recognizes complete delimiter" do
      r = LLMStreamService.process_delta_parts("---JSON DATA---", false, "")
      assert {"", true, ""} == r
    end

    test "handles content before a complete delimiter" do
      r =
        LLMStreamService.process_delta_parts(
          "How are you?\n---JSON DATA---",
          false,
          ""
        )

      assert {"How are you?\n", true, ""} == r
    end

    test "buffers content that might be part of delimiter" do
      r = LLMStreamService.process_delta_parts("Hello!\n--", false, "")
      assert {"Hello!\n", false, "--"} == r
    end

    test "builds up buffer while it could match delimiter" do
      r = LLMStreamService.process_delta_parts("-J", false, "--")
      assert {"", false, "---J"} == r
    end

    test "flushes buffer when it can no longer match delimiter" do
      r = LLMStreamService.process_delta_parts("tricked ya!-", false, "---JSON")
      assert {"---JSONtricked ya!", false, "-"} == r
    end
  end
end
