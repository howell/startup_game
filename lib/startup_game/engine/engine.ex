defmodule StartupGame.Engine do
  @moduledoc """
  Core game engine that manages game state and processes player actions.

  This module provides the main functionality for creating and running games,
  processing player choices, and updating the game state.
  """

  alias StartupGame.Engine.{GameState, Scenario, ScenarioManager}

  @doc """
  Creates a new game with the given startup name and description.

  ## Examples

      iex> Engine.new_game("TechNova", "AI-powered project management")
      %GameState{name: "TechNova", description: "AI-powered project management", ...}

  """
  @spec new_game(String.t(), String.t()) :: GameState.t()
  def new_game(name, description) do
    game_state = GameState.new(name, description)

    # Assign the first scenario
    scenario_id = ScenarioManager.get_initial_scenario_id()
    %{game_state | current_scenario: scenario_id}
  end

  @doc """
  Gets the current scenario description and choices.

  ## Examples

      iex> Engine.get_current_situation(game_state)
      %{situation: "An angel investor offers...", choices: [%{id: "accept", ...}, ...]}

  """
  @spec get_current_situation(GameState.t()) :: %{situation: String.t(), choices: list(map())}
  def get_current_situation(game_state) do
    scenario = ScenarioManager.get_scenario(game_state.current_scenario)

    %{
      situation: scenario.situation,
      choices: scenario.choices
    }
  end

  @doc """
  Processes a player's choice and advances the game state.

  ## Examples

      iex> Engine.process_choice(game_state, "accept")
      %GameState{...}

  """
  @spec process_choice(GameState.t(), String.t()) :: GameState.t()
  def process_choice(game_state, choice_id) do
    scenario = ScenarioManager.get_scenario(game_state.current_scenario)

    # Get the outcome for this choice
    outcome = Map.get(scenario.outcomes, choice_id)

    # Create the round entry
    round = %{
      scenario_id: scenario.id,
      situation: scenario.situation,
      response: get_choice_text(scenario, choice_id),
      outcome: outcome.text,
      cash_change: outcome.cash_change,
      burn_rate_change: outcome.burn_rate_change,
      ownership_changes: outcome.ownership_changes
    }

    # Update game state
    game_state = update_finances(game_state, outcome)
    game_state = update_ownership(game_state, outcome)
    game_state = check_game_end(game_state, outcome)

    # Add the round and get next scenario
    game_state = %{game_state | rounds: game_state.rounds ++ [round]}

    if game_state.status == :in_progress do
      next_scenario_id = ScenarioManager.get_next_scenario_id(game_state)
      %{game_state | current_scenario: next_scenario_id}
    else
      %{game_state | current_scenario: nil}
    end
  end

  # Helper functions

  @spec get_choice_text(Scenario.t(), String.t()) :: String.t()
  defp get_choice_text(scenario, choice_id) do
    Enum.find(scenario.choices, fn choice -> choice.id == choice_id end).text
  end

  @spec update_finances(GameState.t(), map()) :: GameState.t()
  defp update_finances(game_state, outcome) do
    new_cash = Decimal.add(game_state.cash_on_hand, outcome.cash_change || Decimal.new("0"))
    new_burn = Decimal.add(game_state.burn_rate, outcome.burn_rate_change || Decimal.new("0"))

    %{game_state | cash_on_hand: new_cash, burn_rate: new_burn}
  end

  @spec update_ownership(GameState.t(), map()) :: GameState.t()
  defp update_ownership(game_state, outcome) do
    if outcome.ownership_changes do
      new_ownerships = apply_ownership_changes(game_state.ownerships, outcome.ownership_changes)
      %{game_state | ownerships: new_ownerships}
    else
      game_state
    end
  end

  @spec apply_ownership_changes([GameState.ownership_entry()], [GameState.ownership_change()]) ::
          [GameState.ownership_entry()]
  defp apply_ownership_changes(current_ownerships, changes) do
    # Create a map of current ownerships by entity name for easy lookup
    current_by_entity =
      Enum.reduce(current_ownerships, %{}, fn ownership, acc ->
        Map.put(acc, ownership.entity_name, ownership)
      end)

    # Process each change
    Enum.reduce(changes, [], fn change, acc ->
      # Check if the entity already exists
      case Map.get(current_by_entity, change.entity_name) do
        nil ->
          # New entity
          [%{entity_name: change.entity_name, percentage: change.new_percentage} | acc]

        _existing ->
          # Update existing entity
          [%{entity_name: change.entity_name, percentage: change.new_percentage} | acc]
      end
    end)
    |> Enum.reverse()
  end

  @spec check_game_end(GameState.t(), map()) :: GameState.t()
  defp check_game_end(game_state, outcome) do
    cond do
      # Check for exit events
      outcome.exit_type in [:acquisition, :ipo] ->
        %{
          game_state
          | status: :completed,
            exit_type: outcome.exit_type,
            exit_value: outcome.exit_value
        }

      # Check for bankruptcy
      Decimal.compare(game_state.cash_on_hand, Decimal.new("0")) == :lt ->
        %{game_state | status: :failed, exit_type: :shutdown}

      # Check for insufficient runway
      Decimal.compare(GameState.calculate_runway(game_state), Decimal.new("1")) == :lt ->
        %{game_state | status: :failed, exit_type: :shutdown}

      true ->
        game_state
    end
  end
end
