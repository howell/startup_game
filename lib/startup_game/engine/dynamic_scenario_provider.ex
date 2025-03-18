defmodule StartupGame.Engine.DynamicScenarioProvider do
  @moduledoc """
  Provides dynamically generated scenarios, potentially using an LLM.
  Implements the ScenarioProvider behavior.
  """

  @behaviour StartupGame.Engine.ScenarioProvider

  alias StartupGame.Engine.GameState
  alias StartupGame.Engine.Scenario

  @impl true
  @spec get_initial_scenario(GameState.t()) :: Scenario.t()
  def get_initial_scenario(game_state) do
    # Generate an initial scenario based on the startup description
    generate_scenario(game_state, :initial)
  end

  @impl true
  @spec get_next_scenario(GameState.t(), String.t()) :: Scenario.t() | nil
  def get_next_scenario(game_state, _current_scenario_id) do
    # Check if the game should end
    if should_end_game?(game_state) do
      nil
    else
      # Generate a new scenario based on game history
      generate_scenario(game_state, :next)
    end
  end

  @impl true
  @spec generate_outcome(GameState.t(), Scenario.t(), String.t(), String.t()) :: map()
  def generate_outcome(game_state, scenario, choice_id, response_text) do
    # Generate an outcome based on the player's choice and response text
    # This would likely call an LLM to evaluate the response
    generate_dynamic_outcome(game_state, scenario, choice_id, response_text)
  end

  # Private helper functions

  @spec generate_scenario(GameState.t(), :initial | :next) :: Scenario.t()
  defp generate_scenario(game_state, type) do
    # In a real implementation, this would call an LLM
    # For now, we'll use a simple placeholder implementation
    case type do
      :initial ->
        %Scenario{
          id: "dynamic_#{:rand.uniform(1000)}",
          type: :funding,
          situation: "Based on your startup '#{game_state.name}', an angel investor is interested...",
          choices: [
            %{id: "accept", text: "Accept their offer"},
            %{id: "negotiate", text: "Try to negotiate better terms"},
            %{id: "decline", text: "Decline the offer"}
          ],
          outcomes: %{} # Outcomes will be generated dynamically
        }
      :next ->
        # Generate based on game history
        generate_scenario_from_history(game_state)
    end
  end

  @spec generate_dynamic_outcome(GameState.t(), Scenario.t(), String.t(), String.t()) :: map()
  defp generate_dynamic_outcome(_game_state, _scenario, choice_id, response_text) do
    # This would analyze the response text using an LLM and generate an appropriate outcome
    # For now, we'll use a simple placeholder implementation
    case choice_id do
      "accept" ->
        %{
          choice_id: "accept",
          text: "Your response: '#{String.slice(response_text, 0, 30)}...' led to the investor accepting your terms.",
          cash_change: Decimal.new("100000.00"),
          burn_rate_change: Decimal.new("0.00"),
          ownership_changes: [
            %{entity_name: "Founder", previous_percentage: Decimal.new("100.00"), new_percentage: Decimal.new("85.00")},
            %{entity_name: "Angel Investor", previous_percentage: Decimal.new("0.00"), new_percentage: Decimal.new("15.00")}
          ],
          exit_type: :none
        }
      "negotiate" ->
        %{
          choice_id: "negotiate",
          text: "Your negotiation approach: '#{String.slice(response_text, 0, 30)}...' was successful. The investor agreed to better terms.",
          cash_change: Decimal.new("100000.00"),
          burn_rate_change: Decimal.new("0.00"),
          ownership_changes: [
            %{entity_name: "Founder", previous_percentage: Decimal.new("100.00"), new_percentage: Decimal.new("90.00")},
            %{entity_name: "Angel Investor", previous_percentage: Decimal.new("0.00"), new_percentage: Decimal.new("10.00")}
          ],
          exit_type: :none
        }
      "decline" ->
        %{
          choice_id: "decline",
          text: "You declined with this explanation: '#{String.slice(response_text, 0, 30)}...'. The investor respects your decision.",
          cash_change: Decimal.new("0.00"),
          burn_rate_change: Decimal.new("0.00"),
          ownership_changes: nil,
          exit_type: :none
        }
      _ ->
        # Default outcome for any other choice
        %{
          choice_id: choice_id,
          text: "Your response was processed.",
          cash_change: Decimal.new("0.00"),
          burn_rate_change: Decimal.new("0.00"),
          ownership_changes: nil,
          exit_type: :none
        }
    end
  end

  @spec generate_scenario_from_history(GameState.t()) :: Scenario.t()
  defp generate_scenario_from_history(game_state) do
    # Analyze game history to generate an appropriate next scenario
    # This would be a good place to use an LLM

    # For now, we'll use a simple placeholder implementation
    # that generates different scenarios based on the number of rounds
    round_count = length(game_state.rounds)

    case rem(round_count, 3) do
      0 ->
        # Funding scenario
        %Scenario{
          id: "dynamic_funding_#{:rand.uniform(1000)}",
          type: :funding,
          situation: "A venture capital firm has noticed your startup's progress and is interested in investing $500,000 for a stake in your company.",
          choices: [
            %{id: "accept", text: "Accept their offer"},
            %{id: "negotiate", text: "Try to negotiate better terms"},
            %{id: "decline", text: "Decline the offer"}
          ],
          outcomes: %{} # Outcomes will be generated dynamically
        }
      1 ->
        # Hiring scenario
        %Scenario{
          id: "dynamic_hiring_#{:rand.uniform(1000)}",
          type: :hiring,
          situation: "Your startup needs to expand. You can either hire a team of junior developers or a single experienced CTO.",
          choices: [
            %{id: "team", text: "Hire a team of junior developers"},
            %{id: "cto", text: "Hire an experienced CTO"}
          ],
          outcomes: %{} # Outcomes will be generated dynamically
        }
      2 ->
        # Product scenario
        %Scenario{
          id: "dynamic_product_#{:rand.uniform(1000)}",
          type: :other,
          situation: "Your product is at a crossroads. You can either focus on adding new features or improving the existing user experience.",
          choices: [
            %{id: "features", text: "Focus on adding new features"},
            %{id: "ux", text: "Focus on improving user experience"}
          ],
          outcomes: %{} # Outcomes will be generated dynamically
        }
    end
  end

  @spec should_end_game?(GameState.t()) :: boolean()
  defp should_end_game?(game_state) do
    # Logic to determine if the game should end
    # Could be based on number of rounds, financial state, etc.

    # For now, end after 5 rounds
    length(game_state.rounds) >= 5 or
      # Or if cash is too low
      Decimal.compare(game_state.cash_on_hand, Decimal.new("0")) == :lt or
      # Or if runway is less than 1 month
      Decimal.compare(GameState.calculate_runway(game_state), Decimal.new("1")) == :lt
  end
end
