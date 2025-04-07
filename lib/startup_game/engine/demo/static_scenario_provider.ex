defmodule StartupGame.Engine.Demo.StaticScenarioProvider do
  @moduledoc """
  Provides predefined scenarios from a static collection for testing.
  Implements the ScenarioProvider behavior.
  """
  use StartupGame.Engine.Demo.BaseScenarioProvider

  alias StartupGame.Engine.GameState
  alias StartupGame.Engine.Scenario

  # Fixed sequence for deterministic gameplay
  @scenario_sequence [
    "angel_investment",
    "hiring_decision",
    "lawsuit",
    "acquisition_offer"
  ]

  # Choices for each scenario
  @scenario_choices %{
    "angel_investment" => [
      %{id: "accept", text: "Accept the offer as is", selection_keys: ["a", "accept"]},
      %{
        id: "negotiate",
        text: "Try to negotiate better terms",
        selection_keys: ["n", "negotiate"]
      },
      %{id: "decline", text: "Decline the offer", selection_keys: ["d", "decline"]}
    ],
    "acquisition_offer" => [
      %{id: "accept", text: "Accept the acquisition offer", selection_keys: ["a", "accept"]},
      %{id: "counter", text: "Counter with a higher valuation", selection_keys: ["c", "counter"]},
      %{
        id: "decline",
        text: "Decline and continue building independently",
        selection_keys: ["d", "decline"]
      }
    ],
    "hiring_decision" => [
      %{
        id: "experienced",
        text: "Hire the experienced developer",
        selection_keys: ["e", "experienced"]
      },
      %{
        id: "junior",
        text: "Hire the promising junior developer",
        selection_keys: ["j", "junior"]
      }
    ],
    "lawsuit" => [
      %{id: "settle", text: "Settle out of court", selection_keys: ["s", "settle"]},
      %{id: "fight", text: "Fight the lawsuit", selection_keys: ["f", "fight"]},
      %{id: "license", text: "Offer to license the technology", selection_keys: ["l", "license"]}
    ]
  }

  # Outcomes for each scenario and choice
  @scenario_outcomes %{
    "angel_investment" => %{
      "accept" => %{
        choice_id: "accept",
        text:
          "You accept the offer and receive the investment. Your runway is extended but you've given up a significant portion of your company.",
        cash_change: Decimal.new("100000.00"),
        burn_rate_change: Decimal.new("0.00"),
        ownership_changes: [
          %{
            entity_name: "Founder",
            previous_percentage: Decimal.new("100.00"),
            new_percentage: Decimal.new("85.00")
          },
          %{
            entity_name: "Angel Investor",
            previous_percentage: Decimal.new("0.00"),
            new_percentage: Decimal.new("15.00")
          }
        ],
        exit_type: :none
      },
      "negotiate" => %{
        choice_id: "negotiate",
        text: "After negotiation, the investor agrees to $100,000 for 12% of your company.",
        cash_change: Decimal.new("100000.00"),
        burn_rate_change: Decimal.new("0.00"),
        ownership_changes: [
          %{
            entity_name: "Founder",
            previous_percentage: Decimal.new("100.00"),
            new_percentage: Decimal.new("88.00")
          },
          %{
            entity_name: "Angel Investor",
            previous_percentage: Decimal.new("0.00"),
            new_percentage: Decimal.new("12.00")
          }
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
    },
    "acquisition_offer" => %{
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
    },
    "hiring_decision" => %{
      "experienced" => %{
        choice_id: "experienced",
        text:
          "The experienced developer brings immediate value but increases your burn rate significantly.",
        cash_change: Decimal.new("0.00"),
        burn_rate_change: Decimal.new("3000.00"),
        ownership_changes: nil,
        exit_type: :none
      },
      "junior" => %{
        choice_id: "junior",
        text:
          "The junior developer requires more training but costs less, leading to a smaller increase in burn rate.",
        cash_change: Decimal.new("0.00"),
        burn_rate_change: Decimal.new("1500.00"),
        ownership_changes: nil,
        exit_type: :none
      }
    },
    "lawsuit" => %{
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
        text:
          "You decide to fight the lawsuit. Legal fees drain your resources, costing $100,000 over time.",
        cash_change: Decimal.new("-100000.00"),
        burn_rate_change: Decimal.new("2000.00"),
        ownership_changes: nil,
        exit_type: :none
      },
      "license" => %{
        choice_id: "license",
        text:
          "You negotiate a licensing agreement, paying a small ongoing fee to use the technology.",
        cash_change: Decimal.new("-10000.00"),
        burn_rate_change: Decimal.new("500.00"),
        ownership_changes: nil,
        exit_type: :none
      }
    }
  }

  # This function was moved to BaseScenarioProvider

  # Predefined scenarios
  @scenarios %{
    "angel_investment" => %Scenario{
      id: "angel_investment",
      type: :funding,
      situation: "An angel investor offers $100,000 for 15% of your company."
    },
    "acquisition_offer" => %Scenario{
      id: "acquisition_offer",
      type: :acquisition,
      situation: "A larger company offers to acquire your startup for $2 million."
    },
    "hiring_decision" => %Scenario{
      id: "hiring_decision",
      type: :hiring,
      situation:
        "You need to hire a key employee. You have two candidates: an experienced developer demanding a high salary, or a promising junior who would cost much less."
    },
    "lawsuit" => %Scenario{
      id: "lawsuit",
      type: :legal,
      situation:
        "Your startup has been sued by a competitor claiming you've infringed on their patent."
    }
  }

  @impl true
  @spec get_next_scenario(GameState.t(), String.t() | nil) :: Scenario.t() | nil
  def get_next_scenario(game_state, current_scenario_id) do
    # Return nil if the game has ended
    if game_state.status != :in_progress do
      nil
    else
      # Get the appropriate scenario ID
      next_id = get_next_scenario_id(game_state, current_scenario_id)

      # Fetch and prepare the scenario
      create_scenario_with_choices(next_id)
    end
  end

  # Helper to determine the next scenario ID based on the current one
  @spec get_next_scenario_id(GameState.t(), String.t() | nil) :: String.t()
  defp get_next_scenario_id(game_state, current_scenario_id) do
    # For initial scenario
    if is_nil(current_scenario_id) && Enum.empty?(game_state.rounds) do
      List.first(@scenario_sequence)
    else
      # Otherwise, find the next in sequence
      current =
        game_state.current_scenario_data || List.last(game_state.rounds) |> scenario_for_round()

      key = key_for(current)
      current_index = Enum.find_index(@scenario_sequence, fn id -> id == key end)

      # Calculate the next index, looping if necessary
      next_index =
        if current_index < length(@scenario_sequence) - 1 do
          current_index + 1
        else
          # Loop back to the first scenario
          0
        end

      Enum.at(@scenario_sequence, next_index)
    end
  end

  @spec scenario_for_round(GameState.round_entry()) :: Scenario.t()
  defp scenario_for_round(round) do
    %Scenario{
      id: round.scenario_id,
      type: :other,
      situation: round.situation
    }
  end

  # Helper to create a scenario with its choices
  @spec create_scenario_with_choices(String.t()) :: Scenario.t() | nil
  defp create_scenario_with_choices(scenario_id) do
    scenario = Map.get(@scenarios, scenario_id)

    if scenario do
      choices = Map.get(@scenario_choices, scenario_id)
      BaseScenarioProvider.add_choices_to_scenario(scenario, choices)
    else
      nil
    end
  end

  @impl true
  @spec generate_outcome(GameState.t(), Scenario.t(), String.t()) ::
          {:ok, Scenario.outcome()} | {:error, String.t()}
  def generate_outcome(game_state, scenario, response_text) do
    current = scenario || List.last(game_state.rounds) |> scenario_for_round()

    key = key_for(current)
    # Get the choices for this scenario
    choices = Map.get(@scenario_choices, key)

    case BaseScenarioProvider.match_response_to_choice(current, response_text, choices) do
      {:ok, choice_id} ->
        # Get the predefined outcome for this choice
        outcome = get_outcome_for_choice(key, choice_id)
        # Remove the choice_id field from the outcome
        {:ok, Map.delete(outcome, :choice_id)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp key_for(%Scenario{id: id, situation: sit_with_choices}) do
    if Map.has_key?(@scenarios, id) do
      id
    else
      Enum.find(@scenarios, fn {_, situation} ->
        String.contains?(sit_with_choices, situation.situation)
      end)
      |> elem(0)
    end
  end

  # Helper function to get an outcome for a choice
  @spec get_outcome_for_choice(String.t(), String.t()) :: map()
  defp get_outcome_for_choice(scenario_id, choice_id) do
    # Get the outcomes for this scenario
    scenario_outcomes = Map.get(@scenario_outcomes, scenario_id)

    # Get the outcome for this choice
    Map.get(scenario_outcomes, choice_id)
  end
end
