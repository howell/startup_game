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
      {%GameState{...}, %{situation: "An angel investor offers..."}}

  """
  @spec start_game(String.t(), String.t(), ScenarioProvider.behaviour()) ::
          {GameState.t(), %{situation: String.t()}}
  def start_game(name, description, provider) do
    game_state = Engine.new_game(name, description, provider) |> Engine.set_next_scenario()

    situation = Engine.get_current_situation(game_state)

    {game_state, situation}
  end

  # make_choice/2 removed as it was just an alias for make_response

  @doc """
  Processes a player's input (response or action) and returns the updated game state and next situation.
  Returns nil for the situation if the game has ended.
  Returns the same game state with an error message if the input couldn't be interpreted.

  ## Examples

      iex> GameRunner.process_input(game_state, "I choose option A")
      {%GameState{...}, %{situation: "You need to hire..."}}

      iex> GameRunner.process_input(game_state, "I want to negotiate better terms")
      {%GameState{...}, %{situation: "A venture capital firm..."}}

      iex> GameRunner.process_input(game_state_without_scenario, "Hire a marketing manager")
      {%GameState{...}, %{situation: "A new challenge arises..."}}

  """
  @spec process_input(GameState.t(), String.t()) ::
          {GameState.t(), %{situation: String.t()} | nil}
  def process_input(game_state, player_input) do
    # Process the input using the Engine
    updated_state = Engine.process_player_input(game_state, player_input)

    # Check if there was an error processing the input
    if updated_state.error_message do
      # Return the state with the error message and the *original* situation
      # (or nil if there wasn't one)
      situation =
        if game_state.current_scenario_data do
          Engine.get_current_situation(game_state)
          |> Map.put(:error, updated_state.error_message)
        else
          %{error: updated_state.error_message}
        end

      {updated_state, situation}
    else
      # Input processed successfully, try to set the next scenario
      final_state = Engine.set_next_scenario(updated_state)

      # Determine the next situation to present
      if final_state.status == :in_progress && final_state.current_scenario do
        situation = Engine.get_current_situation(final_state)
        {final_state, situation}
      else
        # Game has ended or no next scenario
        {final_state, nil}
      end
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
  Runs a complete game with the given choices or responses and returns the final game state.
  This is useful for testing or for running predefined scenarios.

  ## Examples

      iex> GameRunner.run_game("TechNova", "AI-powered project management", ["accept", "experienced", "settle", "counter"], StaticScenarioProvider)
      %GameState{status: :completed, exit_type: :acquisition, ...}

      iex> GameRunner.run_game("TechNova", "AI-powered project management", ["I accept the offer", "Hire the experienced developer"], LLMScenarioProvider)
      %GameState{status: :completed, exit_type: :acquisition, ...}

  """
  @spec run_game(String.t(), String.t(), [String.t()], ScenarioProvider.behaviour()) ::
          GameState.t()
  def run_game(name, description, inputs, provider) do
    {game_state, _initial_situation} = start_game(name, description, provider)

    Enum.reduce_while(inputs, game_state, fn input, current_state ->
      # Process the input using the main process_input function
      {updated_state, situation_or_nil} = process_input(current_state, input)

      # Determine whether to continue or halt based on the situation
      determine_continuation(updated_state, situation_or_nil)
    end)
  end

  # Helper to determine whether to continue or halt based on the situation
  # Game has ended or no next situation
  defp determine_continuation(state, nil), do: {:halt, state}
  # Check for error key in the situation map using Map.get instead of pattern matching
  defp determine_continuation(state, situation) do
    case Map.get(situation, :error) do
      # No error, continue with next input
      nil -> {:cont, state}
      # Error in response, halt
      _ -> {:halt, state}
    end
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
