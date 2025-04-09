defmodule StartupGame.Engine.LLM.BaseScenarioProviderTest do
  use ExUnit.Case, async: true

  alias StartupGame.Engine.GameState
  alias StartupGame.Engine.Scenario

  # Define a test provider that uses the base provider
  defmodule TestProvider do
    use StartupGame.Engine.LLM.BaseScenarioProvider

    @impl true
    def llm_adapter, do: StartupGame.Engine.LLM.MockAdapter

    @impl true
    def scenario_system_prompt, do: "Test scenario system prompt"

    @impl true
    def outcome_system_prompt, do: "Test outcome system prompt"
  end

  # Define a test provider with custom behavior
  defmodule CustomTestProvider do
    use StartupGame.Engine.LLM.BaseScenarioProvider

    @impl true
    def llm_adapter, do: StartupGame.Engine.LLM.MockAdapter

    @impl true
    def scenario_system_prompt, do: "Custom scenario system prompt"

    @impl true
    def outcome_system_prompt, do: "Custom outcome system prompt"

    @impl true
    def llm_options, do: %{model: "test-model", response_type: "scenario"}

    @impl true
    def create_scenario_prompt(_game_state, _current_scenario_id) do
      "Custom scenario prompt"
    end

    @impl true
    def create_outcome_prompt(_game_state, _scenario, _response_text) do
      "Custom outcome prompt"
    end

    @impl true
    def should_end_game?(game_state) do
      # End the game after 10 rounds instead of 15
      length(game_state.rounds) >= 10 or
        StartupGame.Engine.LLM.BaseScenarioProvider.default_should_end_game?(game_state)
    end
  end

  # Define a test provider that returns errors
  defmodule ErrorTestProvider do
    use StartupGame.Engine.LLM.BaseScenarioProvider

    @impl true
    def llm_adapter, do: StartupGame.Engine.LLM.MockAdapter

    @impl true
    def scenario_system_prompt, do: "Error scenario system prompt"

    @impl true
    def outcome_system_prompt, do: "Error outcome system prompt"

    @impl true
    def llm_options, do: %{response_type: "error"}
  end

  describe "get_next_scenario/2" do
    setup do
      # Create a basic game state for testing
      game_state = %GameState{
        name: "Test Startup",
        description: "A test startup",
        cash_on_hand: Decimal.new("100000"),
        burn_rate: Decimal.new("10000"),
        ownerships: [
          %{entity_name: "Founder", percentage: Decimal.new("100")}
        ],
        rounds: [
          %{
            situation: "Previous situation",
            player_input: "Previous response",
            outcome: "Previous outcome",
            cash_change: Decimal.new("10000")
          }
        ],
        exit_type: :none,
        exit_value: nil
      }

      {:ok, %{game_state: game_state}}
    end

    test "returns a scenario when the game should continue", %{game_state: game_state} do
      scenario = TestProvider.get_next_scenario(game_state, nil)
      assert %Scenario{} = scenario
      assert scenario.id == "mock_scenario_123"
      assert scenario.type == :funding
    end

    test "returns nil when the game should end", %{game_state: game_state} do
      # Create a game state that should end (15 rounds)
      game_state = %{
        game_state
        | rounds:
            List.duplicate(
              %{
                situation: "Previous situation",
                player_input: "Previous response",
                outcome: "Previous outcome",
                cash_change: Decimal.new("10000")
              },
              15
            )
      }

      assert nil == TestProvider.get_next_scenario(game_state, nil)
    end

    test "uses custom behavior when provided", %{game_state: game_state} do
      # Create a game state that should end with CustomTestProvider (10 rounds)
      game_state = %{
        game_state
        | rounds:
            List.duplicate(
              %{
                situation: "Previous situation",
                player_input: "Previous response",
                outcome: "Previous outcome",
                cash_change: Decimal.new("10000")
              },
              10
            )
      }

      assert nil == CustomTestProvider.get_next_scenario(game_state, nil)

      # But not with the regular TestProvider (needs 15 rounds)
      game_state = %{
        game_state
        | rounds:
            List.duplicate(
              %{
                situation: "Previous situation",
                player_input: "Previous response",
                outcome: "Previous outcome",
                cash_change: Decimal.new("10000")
              },
              9
            )
      }

      assert %Scenario{} = TestProvider.get_next_scenario(game_state, nil)
    end

    test "raises an error when LLM returns an error", %{game_state: game_state} do
      assert_raise RuntimeError, ~r/Failed to generate LLM scenario/, fn ->
        ErrorTestProvider.get_next_scenario(game_state, nil)
      end
    end
  end

  describe "generate_outcome/3" do
    setup do
      # Create a basic game state for testing
      game_state = %GameState{
        name: "Test Startup",
        description: "A test startup",
        cash_on_hand: Decimal.new("100000"),
        burn_rate: Decimal.new("10000"),
        ownerships: [
          %{entity_name: "Founder", percentage: Decimal.new("100")}
        ],
        rounds: [
          %{
            situation: "Previous situation",
            player_input: "Previous response",
            outcome: "Previous outcome",
            cash_change: Decimal.new("10000")
          }
        ],
        exit_type: :none,
        exit_value: nil
      }

      # Create a basic scenario for testing
      scenario = %Scenario{
        id: "test_scenario",
        type: :funding,
        situation: "Test situation"
      }

      {:ok, %{game_state: game_state, scenario: scenario}}
    end

    # We can't test these without meck, so we'll just test the error case
    test "raises an error when LLM returns an error", %{
      game_state: game_state,
      scenario: scenario
    } do
      assert_raise RuntimeError, ~r/Failed to generate LLM outcome/, fn ->
        ErrorTestProvider.generate_outcome(game_state, scenario, "Test response")
      end
    end
  end

  describe "utility functions" do
    test "parse_scenario_type/1 converts strings to atoms" do
      assert :funding ==
               StartupGame.Engine.LLM.BaseScenarioProvider.parse_scenario_type("funding")

      assert :acquisition ==
               StartupGame.Engine.LLM.BaseScenarioProvider.parse_scenario_type("acquisition")

      assert :hiring == StartupGame.Engine.LLM.BaseScenarioProvider.parse_scenario_type("hiring")
      assert :legal == StartupGame.Engine.LLM.BaseScenarioProvider.parse_scenario_type("legal")
      assert :other == StartupGame.Engine.LLM.BaseScenarioProvider.parse_scenario_type("unknown")
    end

    test "parse_decimal/1 converts various formats to Decimal" do
      assert Decimal.equal?(
               Decimal.new("123"),
               StartupGame.Engine.LLM.BaseScenarioProvider.parse_decimal(123)
             )

      assert Decimal.equal?(
               Decimal.new("123.45"),
               StartupGame.Engine.LLM.BaseScenarioProvider.parse_decimal(123.45)
             )

      assert Decimal.equal?(
               Decimal.new("123"),
               StartupGame.Engine.LLM.BaseScenarioProvider.parse_decimal("123")
             )

      assert Decimal.equal?(
               Decimal.new("0"),
               StartupGame.Engine.LLM.BaseScenarioProvider.parse_decimal(nil)
             )
    end

    test "parse_exit_type/1 converts strings to atoms" do
      assert :acquisition ==
               StartupGame.Engine.LLM.BaseScenarioProvider.parse_exit_type("acquisition")

      assert :ipo == StartupGame.Engine.LLM.BaseScenarioProvider.parse_exit_type("ipo")
      assert :shutdown == StartupGame.Engine.LLM.BaseScenarioProvider.parse_exit_type("shutdown")
      assert :none == StartupGame.Engine.LLM.BaseScenarioProvider.parse_exit_type("unknown")
    end

    test "parse_ownership_changes/1 handles various formats" do
      # Test with nil
      assert nil == StartupGame.Engine.LLM.BaseScenarioProvider.parse_ownership_changes(nil)

      # Test with valid list
      changes = [
        %{"entity_name" => "Founder", "previous_percentage" => 100, "new_percentage" => 80},
        %{"entity_name" => "Investor", "previous_percentage" => 0, "new_percentage" => 20}
      ]

      result = StartupGame.Engine.LLM.BaseScenarioProvider.parse_ownership_changes(changes)
      assert length(result) == 2
      assert Enum.at(result, 0).entity_name == "Founder"
      assert Decimal.equal?(Enum.at(result, 0).previous_percentage, Decimal.new("100"))
      assert Decimal.equal?(Enum.at(result, 0).new_percentage, Decimal.new("80"))
    end
  end
end
