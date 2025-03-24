defmodule StartupGame.Engine.ScenarioProvider do
  @moduledoc """
  Behavior that defines the interface for scenario providers.
  Both static and dynamic providers must implement these functions.
  """

  alias StartupGame.Engine.GameState
  alias StartupGame.Engine.Scenario

  @typedoc """
  A module that implements the ScenarioProvider behavior.
  """
  @type behaviour() :: module()

  @type stream_id() :: String.t()

  @doc """
  Returns the next scenario based on the current game state and scenario ID.
  If current_scenario_id is nil, returns the first scenario for the game.
  Returns nil if there are no more scenarios or the game should end.
  Arguments:
    - game_state: The current game state
    - current_scenario_id: The ID of the current scenario, or nil if no scenario has been played yet.
  """
  @callback get_next_scenario(GameState.t(), String.t() | nil) :: Scenario.t() | nil

  @doc """
  Like get_next_scenario, but returns a stream ID for asynchronous processing.
  Arguments:
    - game_state: The current game state
    - game_id: The ID of the current game
    - current_scenario_id: The ID of the current scenario, or nil if no scenario has been played yet.
  """
  @callback get_next_scenario_async(GameState.t(), any(), String.t() | nil) ::
              {:ok, stream_id()} | {:error, String.t()}

  @doc """
  Generates an outcome based on the player's response text.
  Returns {:ok, outcome} if successful, or {:error, reason} if the response couldn't be interpreted.
  """
  @callback generate_outcome(GameState.t(), Scenario.t(), String.t()) ::
              {:ok, Scenario.outcome()} | {:error, String.t()}

  @doc """
  Like generate_outcome, but returns a stream ID for asynchronous processing.
  Arguments:
    - game_state: The current game state
    - game_id: The ID of the current game
    - scenario: The current scenario
    - response_text: The player's response text
  """
  @callback generate_outcome_async(GameState.t(), any(), Scenario.t(), String.t()) ::
              {:ok, stream_id()} | {:error, String.t()}
end
