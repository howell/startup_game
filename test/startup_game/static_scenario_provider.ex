defmodule StartupGame.StaticScenarioProvider do
  @moduledoc """
  Provides predefined scenarios from a static collection for testing.
  Implements the ScenarioProvider behavior.
  """

  @behaviour StartupGame.Engine.ScenarioProvider

  alias StartupGame.Engine.GameState
  alias StartupGame.Engine.Scenario

  # Fixed sequence for deterministic gameplay
  @scenario_sequence [
    "angel_investment",
    "hiring_decision",
    "lawsuit",
    "acquisition_offer"
  ]

  # Predefined scenarios
  @scenarios %{
    "angel_investment" => %Scenario{
      id: "angel_investment",
      type: :funding,
      situation: "An angel investor offers $100,000 for 15% of your company.",
      choices: [
        %{id: "accept", text: "Accept the offer as is"},
        %{id: "negotiate", text: "Try to negotiate better terms"},
        %{id: "decline", text: "Decline the offer"}
      ],
      outcomes: %{
        "accept" => %{
          choice_id: "accept",
          text: "You accept the offer and receive the investment. Your runway is extended but you've given up a significant portion of your company.",
          cash_change: Decimal.new("100000.00"),
          burn_rate_change: Decimal.new("0.00"),
          ownership_changes: [
            %{entity_name: "Founder", previous_percentage: Decimal.new("100.00"), new_percentage: Decimal.new("85.00")},
            %{entity_name: "Angel Investor", previous_percentage: Decimal.new("0.00"), new_percentage: Decimal.new("15.00")}
          ],
          exit_type: :none
        },
        "negotiate" => %{
          choice_id: "negotiate",
          text: "After negotiation, the investor agrees to $100,000 for 12% of your company.",
          cash_change: Decimal.new("100000.00"),
          burn_rate_change: Decimal.new("0.00"),
          ownership_changes: [
            %{entity_name: "Founder", previous_percentage: Decimal.new("100.00"), new_percentage: Decimal.new("88.00")},
            %{entity_name: "Angel Investor", previous_percentage: Decimal.new("0.00"), new_percentage: Decimal.new("12.00")}
          ],
          exit_type: :none
        },
        "decline" => %{
          choice_id: "decline",
          text: "You decide to decline the offer and continue bootstrapping.",
          cash_change: Decimal.new("0.00"),
          burn_rate_change: Decimal.new("0.00"),
          ownership_changes: nil,
          exit_type: :none
        }
      }
    },

    "acquisition_offer" => %Scenario{
      id: "acquisition_offer",
      type: :acquisition,
      situation: "A larger company offers to acquire your startup for $2 million.",
      choices: [
        %{id: "accept", text: "Accept the acquisition offer"},
        %{id: "counter", text: "Counter with a higher valuation"},
        %{id: "decline", text: "Decline and continue building independently"}
      ],
      outcomes: %{
        "accept" => %{
          choice_id: "accept",
          text: "You accept the acquisition offer. Your startup is now part of a larger company.",
          cash_change: Decimal.new("0.00"),
          burn_rate_change: Decimal.new("0.00"),
          ownership_changes: nil,
          exit_type: :acquisition,
          exit_value: Decimal.new("2000000.00")
        },
        "counter" => %{
          choice_id: "counter",
          text: "After negotiation, they increase their offer to $2.5 million, which you accept.",
          cash_change: Decimal.new("0.00"),
          burn_rate_change: Decimal.new("0.00"),
          ownership_changes: nil,
          exit_type: :acquisition,
          exit_value: Decimal.new("2500000.00")
        },
        "decline" => %{
          choice_id: "decline",
          text: "You decide to continue building your company independently.",
          cash_change: Decimal.new("0.00"),
          burn_rate_change: Decimal.new("0.00"),
          ownership_changes: nil,
          exit_type: :none
        }
      }
    },

    "hiring_decision" => %Scenario{
      id: "hiring_decision",
      type: :hiring,
      situation: "You need to hire a key employee. You have two candidates: an experienced developer demanding a high salary, or a promising junior who would cost much less.",
      choices: [
        %{id: "experienced", text: "Hire the experienced developer"},
        %{id: "junior", text: "Hire the promising junior developer"}
      ],
      outcomes: %{
        "experienced" => %{
          choice_id: "experienced",
          text: "The experienced developer brings immediate value but increases your burn rate significantly.",
          cash_change: Decimal.new("0.00"),
          burn_rate_change: Decimal.new("3000.00"),
          ownership_changes: nil,
          exit_type: :none
        },
        "junior" => %{
          choice_id: "junior",
          text: "The junior developer requires more training but costs less, leading to a smaller increase in burn rate.",
          cash_change: Decimal.new("0.00"),
          burn_rate_change: Decimal.new("1500.00"),
          ownership_changes: nil,
          exit_type: :none
        }
      }
    },

    "lawsuit" => %Scenario{
      id: "lawsuit",
      type: :legal,
      situation: "Your startup has been sued by a competitor claiming you've infringed on their patent.",
      choices: [
        %{id: "settle", text: "Settle out of court"},
        %{id: "fight", text: "Fight the lawsuit"},
        %{id: "license", text: "Offer to license the technology"}
      ],
      outcomes: %{
        "settle" => %{
          choice_id: "settle",
          text: "You settle the lawsuit for $50,000, avoiding prolonged legal battles.",
          cash_change: Decimal.new("-50000.00"),
          burn_rate_change: Decimal.new("0.00"),
          ownership_changes: nil,
          exit_type: :none
        },
        "fight" => %{
          choice_id: "fight",
          text: "You decide to fight the lawsuit. Legal fees drain your resources, costing $100,000 over time.",
          cash_change: Decimal.new("-100000.00"),
          burn_rate_change: Decimal.new("2000.00"),
          ownership_changes: nil,
          exit_type: :none
        },
        "license" => %{
          choice_id: "license",
          text: "You negotiate a licensing agreement, paying a small ongoing fee to use the technology.",
          cash_change: Decimal.new("-10000.00"),
          burn_rate_change: Decimal.new("500.00"),
          ownership_changes: nil,
          exit_type: :none
        }
      }
    }
  }

  @impl true
  @spec get_initial_scenario(GameState.t()) :: Scenario.t()
  def get_initial_scenario(_game_state) do
    scenario_id = List.first(@scenario_sequence)
    Map.get(@scenarios, scenario_id)
  end

  @impl true
  @spec get_next_scenario(GameState.t(), String.t()) :: Scenario.t() | nil
  def get_next_scenario(_game_state, current_scenario_id) do
    current_index = Enum.find_index(@scenario_sequence, fn id -> id == current_scenario_id end)

    if current_index < length(@scenario_sequence) - 1 do
      next_id = Enum.at(@scenario_sequence, current_index + 1)
      Map.get(@scenarios, next_id)
    else
      nil  # End of game
    end
  end

  @impl true
  @spec generate_outcome(GameState.t(), Scenario.t(), String.t(), String.t()) :: map()
  def generate_outcome(_game_state, scenario, choice_id, _response_text) do
    # Simply return the predefined outcome for this choice
    Map.get(scenario.outcomes, choice_id)
  end
end
