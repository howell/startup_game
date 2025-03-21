defmodule StartupGame.Engine.LLM.ScenarioProviderCallback do
  @moduledoc """
  Behaviour that defines the callbacks required for LLM scenario providers.

  This behavior defines the interface that must be implemented by modules
  that use the BaseLLMScenarioProvider.
  """

  alias StartupGame.Engine.GameState
  alias StartupGame.Engine.Scenario

  @doc """
  Returns the LLM adapter module to use.

  This module must implement the StartupGame.Engine.LLM.Adapter behaviour.
  """
  @callback llm_adapter() :: module()

  @doc """
  Returns the options to pass to the LLM adapter.

  These options are specific to the LLM adapter being used.
  """
  @callback llm_options() :: map()

  @doc """
  Returns the system prompt for scenario generation.

  This prompt provides context and instructions to the LLM for generating scenarios.
  """
  @callback scenario_system_prompt() :: String.t()

  @doc """
  Returns the system prompt for outcome generation.

  This prompt provides context and instructions to the LLM for generating outcomes.
  """
  @callback outcome_system_prompt() :: String.t()

  @doc """
  Returns the response parser module to use.

  This module must implement the StartupGame.Engine.LLM.ResponseParser behaviour.
  """
  @callback response_parser() :: module()

  @doc """
  Creates a prompt for scenario generation.

  ## Parameters
    - game_state: The current game state
    - current_scenario_id: The ID of the current scenario, or nil if no scenario has been played yet
  """
  @callback create_scenario_prompt(GameState.t(), String.t() | nil) :: String.t()

  @doc """
  Creates a prompt for outcome generation.

  ## Parameters
    - game_state: The current game state
    - scenario: The scenario that was presented to the player
    - response_text: The player's response to the scenario
  """
  @callback create_outcome_prompt(GameState.t(), Scenario.t(), String.t()) :: String.t()

  @doc """
  Determines if the game should end based on the current state.

  ## Parameters
    - game_state: The current game state
  """
  @callback should_end_game?(GameState.t()) :: boolean()

  @optional_callbacks [
    llm_options: 0,
    response_parser: 0,
    create_scenario_prompt: 2,
    create_outcome_prompt: 3,
    should_end_game?: 1
  ]
end
