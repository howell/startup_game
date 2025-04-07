defmodule StartupGame.StreamingService do
  @moduledoc """
  Centralized service for managing LLM streaming through Phoenix PubSub.

  This module provides functions for subscribing to stream updates,
  broadcasting updates, and defines the message types used in the system.

  ## Usage

  ### Subscribing to updates

  ```elixir
  # Subscribe to updates for a game
  StartupGame.StreamingService.subscribe(game_id)

  # Handle incoming messages in a LiveView
  def handle_info(%{event: "llm_delta", payload: payload}, socket) do
    # Process delta update
  end

  def handle_info(%{event: "llm_complete", payload: payload}, socket) do
    # Process completion
  end

  def handle_info(%{event: "llm_error", payload: payload}, socket) do
    # Process error
  end
  ```

  ### Broadcasting updates

  ```elixir
  # Broadcast a delta update
  StartupGame.StreamingService.broadcast_delta(game_id, stream_id, new_content, full_content)

  # Broadcast completion
  StartupGame.StreamingService.broadcast_complete(game_id, stream_id, result)

  # Broadcast error
  StartupGame.StreamingService.broadcast_error(game_id, stream_id, error)
  ```
  """

  @type stream_id :: String.t()
  @type game_id :: Ecto.UUID.t() | String.t()
  @type stream_content :: String.t()
  @type stream_error :: String.t()
  @type stream_result :: {:ok, term()} | {:error, String.t()}

  # Message types
  @type message_type :: :llm_delta | :llm_complete | :llm_error

  # Delta message structure
  @type delta_message :: {:llm_delta, stream_id(), String.t(), String.t()}

  # Complete message structure
  @type complete_message :: {:llm_complete, stream_id(), {:ok, map()} | {:error, term()}}

  # Error message structure
  @type error_message :: {:llm_error, stream_id(), any()}

  @doc """
  Generates a topic string for a given game ID.

  ## Examples

      iex> StreamingService.topic_for_game("123e4567-e89b-12d3-a456-426614174000")
      "llm_stream:123e4567-e89b-12d3-a456-426614174000"

  """
  @spec topic_for_game(game_id()) :: String.t()
  def topic_for_game(game_id), do: "llm_stream:#{game_id}"

  @doc """
  Subscribes the caller to streaming updates for the given game.

  ## Examples

      iex> StreamingService.subscribe("123e4567-e89b-12d3-a456-426614174000")
      :ok

  """
  @spec subscribe(game_id()) :: :ok | {:error, term()}
  def subscribe(game_id) do
    StartupGameWeb.Endpoint.subscribe(topic_for_game(game_id))
  end

  @doc """
  Unsubscribes the caller from streaming updates for the given game.

  ## Examples

      iex> StreamingService.unsubscribe("123e4567-e89b-12d3-a456-426614174000")
      :ok

  """
  @spec unsubscribe(game_id()) :: :ok | {:error, term()}
  def unsubscribe(game_id) do
    StartupGameWeb.Endpoint.unsubscribe(topic_for_game(game_id))
  end

  @doc """
  Broadcasts a delta update for the streaming response.

  ## Parameters

  - `game_id`: The ID of the game
  - `stream_id`: The ID of the stream
  - `new_content`: The new content to append
  - `full_content`: The full content so far

  ## Examples

      iex> StreamingService.broadcast_delta("123e4567-e89b-12d3-a456-426614174000", "stream_1", "new text", "full text")
      :ok

  """
  @spec broadcast_delta(game_id(), stream_id(), String.t(), String.t()) :: :ok
  def broadcast_delta(game_id, stream_id, new_content, full_content) do
    StartupGameWeb.Endpoint.broadcast(
      topic_for_game(game_id),
      "llm_delta",
      {:llm_delta, stream_id, new_content, full_content}
    )
  end

  @doc """
  Broadcasts a completion of the streaming response.

  ## Parameters

  - `game_id`: The ID of the game
  - `stream_id`: The ID of the stream
  - `result`: The result of the stream, either `{:ok, data}` or `{:error, reason}`

  ## Examples

      iex> StreamingService.broadcast_complete("123e4567-e89b-12d3-a456-426614174000", "stream_1", {:ok, %{text: "Complete"}})
      :ok

  """
  @spec broadcast_complete(game_id(), stream_id(), stream_result()) :: :ok
  def broadcast_complete(game_id, stream_id, result) do
    StartupGameWeb.Endpoint.broadcast(
      topic_for_game(game_id),
      "llm_complete",
      {:llm_complete, stream_id, result}
    )
  end

  @doc """
  Broadcasts an error that occurred during streaming.

  ## Parameters

  - `game_id`: The ID of the game
  - `stream_id`: The ID of the stream
  - `error`: The error that occurred

  ## Examples

      iex> StreamingService.broadcast_error("123e4567-e89b-12d3-a456-426614174000", "stream_1", "API error")
      :ok

  """
  @spec broadcast_error(game_id(), stream_id(), any()) :: :ok
  def broadcast_error(game_id, stream_id, error) do
    StartupGameWeb.Endpoint.broadcast(
      topic_for_game(game_id),
      "llm_error",
      {:llm_error, stream_id, error}
    )
  end
end
