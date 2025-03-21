defmodule StartupGame.Engine.LLM.ResponseParser do
  @moduledoc """
  Behaviour for response parsers that can be used with BaseLLMScenarioProvider.

  This defines the interface that all response parsers must implement to be
  compatible with the LLM scenario provider system.
  """

  alias StartupGame.Engine.Scenario

  @doc """
  Parses the LLM response content into a Scenario struct.

  ## Parameters
    - content: The raw content from the LLM response

  ## Returns
    - {:ok, scenario} if successful, where scenario is a Scenario struct
    - {:error, reason} if parsing failed
  """
  @callback parse_scenario(String.t()) :: {:ok, Scenario.t()} | {:error, String.t()}

  @doc """
  Parses the LLM response content into an outcome map.

  ## Parameters
    - content: The raw content from the LLM response

  ## Returns
    - {:ok, outcome} if successful, where outcome is a map with the expected outcome structure
    - {:error, reason} if parsing failed
  """
  @callback parse_outcome(String.t()) :: {:ok, map()} | {:error, String.t()}
end
