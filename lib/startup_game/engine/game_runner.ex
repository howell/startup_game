defmodule StartupGame.Engine.GameRunner do
  @moduledoc """
  Provides functions to run a game from start to finish.

  This module serves as a high-level interface for the game engine,
  making it easy to start games, process player choices, and get
  game summaries. It can be used for testing or as an interface for a UI.
  """

  alias StartupGame.Engine
  alias StartupGame.Engine.GameState
  alias StartupGame.Engine.ScenarioProvider

  @doc """
  Starts a new game and returns the initial game state and situation.

  ## Examples

      iex> GameRunner.start_game("TechNova", "AI-powered project management", StaticScenarioProvider)
      {%GameState{...}, %{situation: "An angel investor offers...", choices: [...]}}

  """
  @spec start_game(String.t(), String.t(), ScenarioProvider.behaviour()) :: {GameState.t(), %{situation: String.t(), choices: list(map())}}
  def start_game(name, description, provider) do
    game_state = Engine.new_game(name, description, provider)
    situation = Engine.get_current_situation(game_state)

    {game_state, situation}
  end

  @doc """
  Processes a player's choice and returns the updated game state and next situation.
  Returns nil for the situation if the game has ended.

  ## Examples

      iex> GameRunner.make_choice(game_state, "accept")
      {%GameState{...}, %{situation: "You need to hire...", choices: [...]}}

  """
  @spec make_choice(GameState.t(), String.t()) :: {GameState.t(), %{situation: String.t(), choices: list(map())} | nil}
  def make_choice(game_state, choice_id) do
    updated_state = Engine.process_choice(game_state, choice_id)

    if updated_state.status == :in_progress && updated_state.current_scenario do
      situation = Engine.get_current_situation(updated_state)
      {updated_state, situation}
    else
      {updated_state, nil}  # Game has ended
    end
  end

  @doc """
  Returns a summary of the game results.

  ## Examples

      iex> GameRunner.get_game_summary(game_state)
      %{result: "Success!", exit_type: :acquisition, exit_value: #Decimal<2000000.00>, rounds_played: 4}

  """
  @spec get_game_summary(GameState.t()) :: %{
    result: String.t(),
    exit_type: atom() | nil,
    exit_value: Decimal.t() | nil,
    reason: String.t() | nil,
    rounds_played: non_neg_integer()
  }
  def get_game_summary(game_state) do
    case game_state.status do
      :completed ->
        %{
          result: "Success!",
          exit_type: game_state.exit_type,
          exit_value: game_state.exit_value,
          rounds_played: length(game_state.rounds)
        }

      :failed ->
        %{
          result: "Game Over",
          reason: "Your startup failed due to #{describe_failure_reason(game_state)}",
          rounds_played: length(game_state.rounds)
        }

      _ ->
        %{
          result: "In Progress",
          rounds_played: length(game_state.rounds)
        }
    end
  end

  @doc """
  Runs a complete game with the given choices and returns the final game state.
  This is useful for testing or for running predefined scenarios.

  ## Examples

      iex> GameRunner.run_game("TechNova", "AI-powered project management", ["accept", "experienced", "settle", "counter"])
      %GameState{status: :completed, exit_type: :acquisition, ...}

  """
  @spec run_game(String.t(), String.t(), [String.t()], ScenarioProvider.behaviour()) :: GameState.t()
  def run_game(name, description, choices, provider) do
    {game_state, _} = start_game(name, description, provider)

    Enum.reduce_while(choices, game_state, fn choice, state ->
      {updated_state, situation} = make_choice(state, choice)

      if situation == nil do
        {:halt, updated_state}  # Game has ended
      else
        {:cont, updated_state}  # Continue with next choice
      end
    end)
  end

  # Helper function to describe the reason for failure
  @spec describe_failure_reason(GameState.t()) :: String.t()
  defp describe_failure_reason(game_state) do
    cond do
      Decimal.compare(game_state.cash_on_hand, Decimal.new("0")) == :lt ->
        "running out of cash"
      Decimal.compare(GameState.calculate_runway(game_state), Decimal.new("1")) == :lt ->
        "insufficient runway"
      true ->
        "unforeseen circumstances"
    end
  end
end
