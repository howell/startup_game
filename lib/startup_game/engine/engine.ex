defmodule StartupGame.Engine do
  @moduledoc """
  Core game engine that manages game state and processes player actions.

  This module provides the main functionality for creating and running games,
  processing player choices, and updating the game state.
  """

  alias StartupGame.Engine.{GameState, Scenario, ScenarioProvider}

  @doc """
  Creates a new game with the given startup name, description, and scenario provider.

  ## Examples

      iex> Engine.new_game("TechNova", "AI-powered project management", StaticScenarioProvider)
      %GameState{name: "TechNova", description: "AI-powered project management", scenario_provider: StaticScenarioProvider, ...}

      iex> Engine.new_game("TechNova", "AI-powered project management", DynamicScenarioProvider)
      %GameState{name: "TechNova", description: "AI-powered project management", scenario_provider: DynamicScenarioProvider, ...}

  """
  @spec new_game(String.t(), String.t(), ScenarioProvider.behaviour()) :: GameState.t()
  def new_game(name, description, provider) do
    game_state = GameState.new(name, description)

    # Store the provider module in the game state
    game_state = %{game_state | scenario_provider: provider}

    # Get the initial scenario
    initial_scenario = provider.get_initial_scenario(game_state)
    %{game_state | current_scenario: initial_scenario.id, current_scenario_data: initial_scenario}
  end

  @doc """
  Gets the current scenario description and choices.

  ## Examples

      iex> Engine.get_current_situation(game_state)
      %{situation: "An angel investor offers...", choices: [%{id: "accept", ...}, ...]}

  """
  @spec get_current_situation(GameState.t()) :: %{situation: String.t(), choices: list(map())}
  def get_current_situation(game_state) do
    %{
      situation: game_state.current_scenario_data.situation,
      choices: game_state.current_scenario_data.choices
    }
  end

  @doc """
  Processes a player's choice and advances the game state.

  ## Examples

      iex> Engine.process_choice(game_state, "accept")
      %GameState{...}

      iex> Engine.process_choice(game_state, "negotiate", "I'd like to offer 10% for the same amount")
      %GameState{...}

  """
  @spec process_choice(GameState.t(), String.t(), String.t()) :: GameState.t()
  def process_choice(game_state, choice_id, response_text \\ "") do
    provider = game_state.scenario_provider
    scenario = game_state.current_scenario_data

    # Generate outcome based on the choice and response
    outcome = provider.generate_outcome(game_state, scenario, choice_id, response_text)

    # Create the round entry
    round = %{
      scenario_id: scenario.id,
      situation: scenario.situation,
      response:
        if(response_text == "", do: get_choice_text(scenario, choice_id), else: response_text),
      outcome: outcome.text,
      cash_change: outcome.cash_change,
      burn_rate_change: outcome.burn_rate_change,
      ownership_changes: outcome.ownership_changes
    }

    # Update game state
    game_state = update_finances(game_state, outcome)
    game_state = update_ownership(game_state, outcome)
    game_state = check_game_end(game_state, outcome)

    # Add the round
    game_state = %{game_state | rounds: game_state.rounds ++ [round]}

    if game_state.status == :in_progress do
      # Get next scenario
      next_scenario = provider.get_next_scenario(game_state, scenario.id)

      if next_scenario do
        %{game_state | current_scenario: next_scenario.id, current_scenario_data: next_scenario}
      else
        %{game_state | current_scenario: nil, current_scenario_data: nil, status: :completed}
      end
    else
      %{game_state | current_scenario: nil, current_scenario_data: nil}
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
