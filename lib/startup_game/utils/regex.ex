defmodule StartupGame.Utils.Regex do
  @moduledoc """
  Utility functions for working with regular expressions.
  """

  @doc """
  Compile a regex pattern that matches any of the given prefixes of a string.
  """
  @spec all_prefixes(String.t()) :: Regex.t()
  @spec all_prefixes(String.t(), String.t()) :: Regex.t()
  def all_prefixes(str, suffix \\ "") do
    prefixes = for i <- String.length(str)..1//-1, do: String.slice(str, 0, i)
    prefix_alt_rx = Enum.join(prefixes, "|")

    Regex.compile!("(#{prefix_alt_rx})#{suffix}")
  end
end
