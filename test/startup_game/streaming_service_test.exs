defmodule StartupGame.StreamingServiceTest do
  use StartupGame.DataCase
  alias StartupGame.StreamingService

  describe "topic_for_game/1" do
    test "generates the correct topic string for a game ID" do
      game_id = "123e4567-e89b-12d3-a456-426614174000"
      assert StreamingService.topic_for_game(game_id) == "llm_stream:123e4567-e89b-12d3-a456-426614174000"
    end
  end

  describe "broadcasting functions" do
    test "broadcast_delta/4 sends a delta message to the correct topic" do
      game_id = "test-game-id"
      stream_id = "test-stream-id"
      new_content = "new content"
      full_content = "full content"

      # Set up a test process to receive broadcast messages
      Phoenix.PubSub.subscribe(StartupGame.PubSub, StreamingService.topic_for_game(game_id))

      # Broadcast a delta message
      StreamingService.broadcast_delta(game_id, stream_id, new_content, full_content)

      # Assert that we receive the expected message
      assert_receive %Phoenix.Socket.Broadcast{
        event: "llm_delta",
        payload: {:llm_delta, ^stream_id, ^new_content, ^full_content},
        topic: "llm_stream:test-game-id"
      }
    end

    test "broadcast_complete/3 sends a completion message to the correct topic" do
      game_id = "test-game-id"
      stream_id = "test-stream-id"
      result = {:ok, %{text: "Complete"}}

      # Set up a test process to receive broadcast messages
      Phoenix.PubSub.subscribe(StartupGame.PubSub, StreamingService.topic_for_game(game_id))

      # Broadcast a completion message
      StreamingService.broadcast_complete(game_id, stream_id, result)

      # Assert that we receive the expected message
      assert_receive %Phoenix.Socket.Broadcast{
        event: "llm_complete",
        payload: {:llm_complete, ^stream_id, ^result},
        topic: "llm_stream:test-game-id"
      }
    end

    test "broadcast_error/3 sends an error message to the correct topic" do
      game_id = "test-game-id"
      stream_id = "test-stream-id"
      error = "Test error"

      # Set up a test process to receive broadcast messages
      Phoenix.PubSub.subscribe(StartupGame.PubSub, StreamingService.topic_for_game(game_id))

      # Broadcast an error message
      StreamingService.broadcast_error(game_id, stream_id, error)

      # Assert that we receive the expected message
      assert_receive %Phoenix.Socket.Broadcast{
        event: "llm_error",
        payload: {:llm_error, ^stream_id, ^error},
        topic: "llm_stream:test-game-id"
      }
    end
  end

  describe "subscription functions" do
    test "subscribe/1 subscribes the caller to the correct topic" do
      game_id = "test-game-id"
      topic = StreamingService.topic_for_game(game_id)

      # Subscribe to the topic
      assert :ok = StreamingService.subscribe(game_id)

      # Verify subscription by broadcasting a message and checking if we receive it
      Phoenix.PubSub.broadcast(StartupGame.PubSub, topic, %{event: "test_event", payload: %{data: "test"}})
      assert_receive %{event: "test_event", payload: %{data: "test"}}
    end

    test "unsubscribe/1 unsubscribes the caller from the topic" do
      game_id = "test-game-id"
      topic = StreamingService.topic_for_game(game_id)

      # Subscribe first
      StreamingService.subscribe(game_id)

      # Then unsubscribe
      assert :ok = StreamingService.unsubscribe(game_id)

      # Verify unsubscription by broadcasting a message and checking that we don't receive it
      Phoenix.PubSub.broadcast(StartupGame.PubSub, topic, %{event: "test_event", payload: %{data: "test"}})
      refute_receive %{event: "test_event"}, 100
    end
  end
end
