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

  @doc """
  Returns the initial scenario for a new game.
  """
  @callback get_initial_scenario(GameState.t()) :: Scenario.t()

  @doc """
  Returns the next scenario based on the current game state and scenario ID.
  Returns nil if there are no more scenarios or the game should end.
  """
  @callback get_next_scenario(GameState.t(), String.t()) :: Scenario.t() | nil

  @doc """
  Generates an outcome based on the player's response text.
  Returns {:ok, outcome} if successful, or {:error, reason} if the response couldn't be interpreted.
  """
  @callback generate_outcome(GameState.t(), Scenario.t(), String.t()) ::
              {:ok, Scenario.outcome()} | {:error, String.t()}
end
