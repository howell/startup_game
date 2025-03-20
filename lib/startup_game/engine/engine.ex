defmodule StartupGame.Engine do
  @moduledoc """
  Core game engine that manages game state and processes player actions.

  This module provides the main functionality for creating and running games,
  processing player choices, and updating the game state.
  """

  alias StartupGame.Engine.{GameState, Scenario, ScenarioProvider}

  @doc """
  Creates a new game with the given startup name, description, and scenario provider.
  Does not set the initial scenario - use set_next_scenario/1 after creating the game
  to set the first scenario.

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
    %{game_state | scenario_provider: provider}
  end

  @doc """
  Sets the next scenario for the game state.
  If the current scenario is nil, sets the first scenario.
  Returns the game state with the updated scenario.

  ## Examples

      iex> game_state = Engine.new_game("TechNova", "AI-powered project management", StaticScenarioProvider)
      iex> Engine.set_next_scenario(game_state)
      %GameState{current_scenario: "angel_investment", ...}

  """
  @spec set_next_scenario(GameState.t()) :: GameState.t()
  def set_next_scenario(%GameState{status: :in_progress} = game_state) do
    provider = game_state.scenario_provider
    current_scenario_id = game_state.current_scenario
    next_scenario = provider.get_next_scenario(game_state, current_scenario_id)

    if next_scenario do
      %{game_state | current_scenario: next_scenario.id, current_scenario_data: next_scenario}
    else
      %{game_state | current_scenario: nil, current_scenario_data: nil, status: :completed}
    end
  end

  def set_next_scenario(game_state), do: game_state

  @doc """
  Gets the current scenario description.

  ## Examples

      iex> Engine.get_current_situation(game_state)
      %{situation: "An angel investor offers..."}

  """
  @spec get_current_situation(GameState.t()) :: %{situation: String.t()}
  def get_current_situation(game_state) do
    scenario = game_state.current_scenario_data

    %{
      situation: scenario.situation
    }
  end

  @doc """
  Processes a player's response and advances the game state.

  ## Examples

      iex> Engine.process_response(game_state, "I accept the offer")
      %GameState{...}

      iex> Engine.process_response(game_state, "I'd like to negotiate better terms")
      %GameState{...}

  """
  @spec process_response(GameState.t(), String.t()) :: GameState.t()
  def process_response(game_state, response_text) do
    provider = game_state.scenario_provider
    scenario = game_state.current_scenario_data

    # Clear any previous error message
    game_state = %{game_state | error_message: nil}

    if scenario do
      # Generate outcome based on the response
      case provider.generate_outcome(game_state, scenario, response_text) do
        {:ok, outcome} ->
          # Process the outcome
          process_outcome(game_state, scenario, outcome, response_text)

        {:error, reason} ->
          # Add an error to the game state
          %{game_state | error_message: reason}
      end
    else
      %{game_state | error_message: "No scenario available"}
    end
  end

  # Helper function to process an outcome
  @spec process_outcome(GameState.t(), Scenario.t(), map(), String.t()) :: GameState.t()
  defp process_outcome(game_state, scenario, outcome, response_text) do
    # Create the round entry
    round = %{
      scenario_id: scenario.id,
      situation: scenario.situation,
      response: response_text,
      outcome: outcome.text,
      cash_change: outcome.cash_change,
      burn_rate_change: outcome.burn_rate_change,
      ownership_changes: outcome.ownership_changes
    }

    game_state
    |> update_finances(outcome)
    |> update_ownership(outcome)
    |> apply_burn_rate()
    |> check_game_end(outcome)
    |> Map.put(:rounds, game_state.rounds ++ [round])
  end

  # Helper functions

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

  # Apply monthly burn rate to cash on hand.
  # This function deducts the burn rate from the cash on hand,
  # simulating monthly expenses that occur after each situation.
  @spec apply_burn_rate(GameState.t()) :: GameState.t()
  defp apply_burn_rate(game_state) do
    # Subtract burn rate from cash on hand
    new_cash = Decimal.sub(game_state.cash_on_hand, game_state.burn_rate)
    %{game_state | cash_on_hand: new_cash}
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
