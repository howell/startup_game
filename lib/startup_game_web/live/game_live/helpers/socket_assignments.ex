defmodule StartupGameWeb.GameLive.Helpers.SocketAssignments do
  @moduledoc """
  Helper functions for managing socket assignments in the GameLive modules.
  Provides consistent patterns for common assignment operations.
  """

  use StartupGameWeb, :html

  @type socket :: Phoenix.LiveView.Socket.t()
  @type stream_id :: String.t()
  @type streaming_type :: :outcome | :scenario

  @doc """
  Sets up socket assigns for streaming operations.
  """
  @spec assign_streaming(socket(), stream_id(), streaming_type()) :: socket()
  def assign_streaming(socket, stream_id, streaming_type) do
    socket
    |> assign(:streaming, true)
    |> assign(:stream_id, stream_id)
    |> assign(:streaming_type, streaming_type)
    |> assign(:partial_content, "")
  end

  @doc """
  Resets streaming-related socket assigns.
  """
  @spec reset_streaming(socket()) :: socket()
  def reset_streaming(socket) do
    socket
    |> assign(:streaming, false)
    |> assign(:stream_id, nil)
    |> assign(:streaming_type, nil)
    |> assign(:partial_content, "")
  end

  @doc """
  Updates socket assigns with game data.
  """
  @spec assign_game_data(socket(), map(), map(), [map()], [map()]) :: socket()
  def assign_game_data(socket, game, game_state, rounds, ownerships) do
    socket
    |> assign(:game, game)
    |> assign(:game_state, game_state)
    |> assign(:rounds, rounds)
    |> assign(:ownerships, ownerships)
  end

  @doc """
  Sets up initial socket assigns for a new game.
  """
  @spec initialize_socket(socket()) :: socket()
  def initialize_socket(socket) do
    socket
    |> assign(:creation_stage, :name_input)
    |> assign(:temp_name, nil)
    |> assign(:temp_description, nil)
    |> assign(:game_id, nil)
    |> assign(:response, "")
    |> assign(:ownerships, [])
    |> assign(:initial_player_mode, :responding)
    |> reset_streaming()
  end
end
