defmodule StartupGameWeb.GameLive.Helpers.GameFormatters do
  @moduledoc """
  Helper functions for formatting game values.
  """

  @doc """
  Formats a Decimal value as an abbreviated money string.
  Examples:
  - 999 -> $999.00
  - 1,500 -> $1.5k
  - 2,500,000 -> $2.5M
  - 3,500,000,000 -> $3.5B
  """
  @spec format_money(Decimal.t()) :: String.t()
  def format_money(value) do
    # Get the absolute value for comparison
    abs_value = Decimal.abs(value)

    cond do
      # Less than 1,000 - no abbreviation
      Decimal.lt?(abs_value, Decimal.new(1000)) ->
        Decimal.round(value, 2) |> Decimal.to_string()

      # Thousands (k)
      Decimal.lt?(abs_value, Decimal.new(1_000_000)) ->
        k_value = Decimal.div(value, Decimal.new(1000))
        # Format with one decimal place
        formatted = Decimal.round(k_value, 1) |> Decimal.to_string()
        "#{formatted}k"

      # Millions (M)
      Decimal.lt?(abs_value, Decimal.new(1_000_000_000)) ->
        m_value = Decimal.div(value, Decimal.new(1_000_000))
        formatted = Decimal.round(m_value, 1) |> Decimal.to_string()
        "#{formatted}M"

      # Billions (B)
      true ->
        b_value = Decimal.div(value, Decimal.new(1_000_000_000))
        formatted = Decimal.round(b_value, 1) |> Decimal.to_string()
        "#{formatted}B"
    end
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
