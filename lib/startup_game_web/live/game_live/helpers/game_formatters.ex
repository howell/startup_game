defmodule StartupGameWeb.GameLive.Helpers.GameFormatters do
  @moduledoc """
  Helper functions for formatting game values.
  """

  @doc """
  Formats a Decimal value as a money string with 2 decimal places.
  """
  @spec format_money(Decimal.t()) :: String.t()
  def format_money(value) do
    value
    |> Decimal.to_float()
    |> :erlang.float_to_binary(decimals: 2)
  end

  @doc """
  Formats a Decimal value as a percentage string with 1 decimal place.
  """
  @spec format_percentage(Decimal.t()) :: String.t()
  def format_percentage(value) do
    value
    |> Decimal.to_float()
    |> :erlang.float_to_binary(decimals: 1)
  end

  @doc """
  Formats a Decimal value as a runway string with 1 decimal place.
  """
  @spec format_runway(Decimal.t()) :: String.t()
  def format_runway(value) do
    value
    |> Decimal.to_float()
    |> :erlang.float_to_binary(decimals: 1)
  end

  @doc """
  Returns a status string based on the game's status and exit type.
  """
  @spec game_end_status(map()) :: String.t()
  def game_end_status(%{status: :completed, exit_type: :acquisition}), do: "Acquired!"
  def game_end_status(%{status: :completed, exit_type: :ipo}), do: "IPO Successful!"
  def game_end_status(%{status: :failed}), do: "Failed"

  @doc """
  Returns a message describing the game's end state.
  """
  @spec game_end_message(map()) :: String.t()
  def game_end_message(%{status: :completed, exit_type: :acquisition, exit_value: value}) do
    "Congratulations! Your company was acquired for $#{format_money(value)}."
  end

  def game_end_message(%{status: :completed, exit_type: :ipo, exit_value: value}) do
    "Congratulations! Your company went public with a valuation of $#{format_money(value)}."
  end

  def game_end_message(%{status: :failed, exit_type: :shutdown}) do
    "Unfortunately, your startup ran out of money and had to shut down."
  end

  def game_end_message(_game) do
    "Your startup journey has ended."
  end
end
