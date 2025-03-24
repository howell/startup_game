defmodule StartupGameWeb.GameLive.Helpers.ErrorHandler do
  @moduledoc """
  Helper functions for handling errors in the GameLive modules.
  Provides consistent error handling and formatting.
  """

  use StartupGameWeb, :html

  @type socket :: Phoenix.LiveView.Socket.t()
  @type error_type :: :game_creation | :response_processing | :recovery | :provider_change | :general

  @doc """
  Handles game-related errors with consistent formatting and flash messages.
  """
  @spec handle_game_error(socket(), error_type(), any()) :: {:noreply, socket()}
  def handle_game_error(socket, type, reason) do
    message = format_error_message(type, reason)

    {:noreply,
     socket
     |> Phoenix.LiveView.put_flash(:error, message)}
  end

  @doc """
  Formats error messages based on error type and reason.
  """
  @spec format_error_message(error_type(), any()) :: String.t()
  def format_error_message(:game_creation, %Ecto.Changeset{}) do
    "Failed to create game: Invalid input"
  end

  def format_error_message(:game_creation, reason) do
    "Failed to create game: #{inspect(reason)}"
  end

  def format_error_message(:response_processing, reason) do
    "Error processing response: #{inspect(reason)}"
  end

  def format_error_message(:recovery, reason) do
    "Error recovering game state: #{inspect(reason)}"
  end

  def format_error_message(:provider_change, _reason) do
    "Failed to update scenario provider"
  end

  def format_error_message(:general, reason) do
    "An error occurred: #{inspect(reason)}"
  end

  def format_error_message(type, reason) do
    "#{type} error: #{inspect(reason)}"
  end
end
