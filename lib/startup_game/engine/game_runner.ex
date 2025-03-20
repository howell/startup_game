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

  @doc """
  Processes a player's choice and returns the updated game state and next situation.
  Returns nil for the situation if the game has ended.
  This function is maintained for backward compatibility.

  ## Examples

      iex> GameRunner.make_choice(game_state, "accept")
      {%GameState{...}, %{situation: "You need to hire..."}}

  """
  @spec make_choice(GameState.t(), String.t()) ::
          {GameState.t(), %{situation: String.t()} | nil}
  def make_choice(game_state, choice_id) do
    # Use make_response internally for consistency
    make_response(game_state, choice_id)
  end

  @doc """
  Processes a player's text response and returns the updated game state and next situation.
  Returns nil for the situation if the game has ended.
  Returns the same game state with an error message if the response couldn't be interpreted.

  ## Examples

      iex> GameRunner.make_response(game_state, "I choose option A")
      {%GameState{...}, %{situation: "You need to hire..."}}

      iex> GameRunner.make_response(game_state, "I want to negotiate better terms")
      {%GameState{...}, %{situation: "A venture capital firm..."}}

  """
  @spec make_response(GameState.t(), String.t()) ::
          {GameState.t(), %{situation: String.t()} | nil}
  def make_response(game_state, response_text) do
    updated_state = Engine.process_response(game_state, response_text)

    # Check if there was an error interpreting the response
    if updated_state.error_message do
      # Return the same game state and situation, but with the error message
      situation = Engine.get_current_situation(updated_state)
      situation = Map.put(situation, :error, updated_state.error_message)
      {updated_state, situation}
    else
      updated_state = Engine.set_next_scenario(updated_state)
      # Process normally
      if updated_state.status == :in_progress && updated_state.current_scenario do
        situation = Engine.get_current_situation(updated_state)
        {updated_state, situation}
      else
        # Game has ended
        {updated_state, nil}
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

      iex> GameRunner.run_game("TechNova", "AI-powered project management", ["accept", "experienced", "settle", "counter"])
      %GameState{status: :completed, exit_type: :acquisition, ...}

      iex> GameRunner.run_game("TechNova", "AI-powered project management", ["I accept the offer", "Hire the experienced developer"], provider, true)
      %GameState{status: :completed, exit_type: :acquisition, ...}

  """
  @spec run_game(String.t(), String.t(), [String.t()], ScenarioProvider.behaviour(), boolean()) ::
          GameState.t()
  def run_game(name, description, inputs, provider, use_text_responses \\ false) do
    {game_state, _} = start_game(name, description, provider)

    Enum.reduce_while(inputs, game_state, fn input, state ->
      # Process the input based on the mode (text response or choice ID)
      {updated_state, situation} = process_input(state, input, use_text_responses)

      # Determine whether to continue or halt based on the situation
      determine_continuation(updated_state, situation)
    end)
  end

  # Helper to process an input based on the mode
  defp process_input(state, input, true), do: make_response(state, input)
  defp process_input(state, input, false), do: make_choice(state, input)

  # Helper to determine whether to continue or halt based on the situation
  # Game has ended
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
