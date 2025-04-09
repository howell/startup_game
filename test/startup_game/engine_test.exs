defmodule StartupGame.EngineTest do
  use ExUnit.Case

  alias StartupGame.Engine
  alias StartupGame.Engine.GameRunner
  alias StartupGame.Engine.Demo.StaticScenarioProvider

  describe "simplified engine" do
    test "creates a new game with initial state" do
      # Create game without scenario
      game_state = Engine.new_game("Test Startup", "A test startup", StaticScenarioProvider)

      # Set the initial scenario
      game_state = Engine.set_next_scenario(game_state)

      assert game_state.name == "Test Startup"
      assert game_state.description == "A test startup"
      assert Decimal.equal?(game_state.cash_on_hand, Decimal.new("10000.00"))
      assert Decimal.equal?(game_state.burn_rate, Decimal.new("1000.00"))
      assert game_state.status == :in_progress
      assert game_state.exit_type == :none
      assert length(game_state.ownerships) == 1
      assert hd(game_state.ownerships).entity_name == "Founder"
      assert Decimal.equal?(hd(game_state.ownerships).percentage, Decimal.new("100.00"))
      assert game_state.current_scenario == "angel_investment"
    end

    test "processes player choices and updates game state" do
      # Create game without scenario
      game_state = Engine.new_game("Test Startup", "A test startup", StaticScenarioProvider)

      # Set the initial scenario
      game_state = Engine.set_next_scenario(game_state)

      # Accept angel investment
      updated_state =
        Engine.process_player_input(game_state, "accept") |> Engine.set_next_scenario()

      # Check that cash was updated (initial $10,000 + $100,000 from investment - $1,000 burn rate)
      assert Decimal.equal?(updated_state.cash_on_hand, Decimal.new("109000.00"))

      # Check that ownership was updated
      assert length(updated_state.ownerships) == 2
      founder = Enum.find(updated_state.ownerships, fn o -> o.entity_name == "Founder" end)

      investor =
        Enum.find(updated_state.ownerships, fn o -> o.entity_name == "Angel Investor" end)

      assert Decimal.equal?(founder.percentage, Decimal.new("85.00"))
      assert Decimal.equal?(investor.percentage, Decimal.new("15.00"))

      # Check that round was recorded
      assert length(updated_state.rounds) == 1
      assert hd(updated_state.rounds).scenario_id == "angel_investment"
      # Check renamed field
      assert hd(updated_state.rounds).player_input == "accept"

      # Check that next scenario was set
      assert updated_state.current_scenario == "hiring_decision"
    end

    test "completes a game with acquisition" do
      # Run a complete game with predefined choices
      final_state =
        GameRunner.run_game(
          "Test Startup",
          "A test startup",
          ["accept", "experienced", "settle", "accept"],
          StaticScenarioProvider
        )

      # Check that game was completed with acquisition
      assert final_state.status == :completed
      assert final_state.exit_type == :acquisition
      assert Decimal.equal?(final_state.exit_value, Decimal.new("2000000.00"))
      assert length(final_state.rounds) == 4
    end
  end

  describe "apply_outcome" do
    test "applies ownership changes for new investor" do
      # Create initial game state
      game_state = Engine.new_game("Test Startup", "A test startup", StaticScenarioProvider)

      # Create an outcome with ownership changes
      outcome = %{
        text: "Angel investor joins the company",
        cash_change: Decimal.new("100000.00"),
        burn_rate_change: Decimal.new("0.00"),
        ownership_changes: [
          %{entity_name: "Founder", new_percentage: Decimal.new("85.00")},
          %{entity_name: "Angel Investor", new_percentage: Decimal.new("15.00")}
        ],
        exit_type: :none
      }

      # Apply the outcome
      updated_state = Engine.apply_outcome(game_state, outcome, "accept investment")

      # Verify ownership structure
      assert length(updated_state.ownerships) == 2

      founder = Enum.find(updated_state.ownerships, fn o -> o.entity_name == "Founder" end)

      investor =
        Enum.find(updated_state.ownerships, fn o -> o.entity_name == "Angel Investor" end)

      assert Decimal.equal?(founder.percentage, Decimal.new("85.00"))
      assert Decimal.equal?(investor.percentage, Decimal.new("15.00"))

      # Verify other state changes
      # 10000 initial + 100000 investment - 1000 burn rate
      assert Decimal.equal?(updated_state.cash_on_hand, Decimal.new("109000.00"))
      # Unchanged
      assert Decimal.equal?(updated_state.burn_rate, Decimal.new("1000.00"))
    end

    test "applies multiple rounds of ownership changes" do
      # Create initial game state
      game_state = Engine.new_game("Test Startup", "A test startup", StaticScenarioProvider)

      # First round: Angel investment
      outcome1 = %{
        text: "Angel investor joins the company",
        cash_change: Decimal.new("100000.00"),
        burn_rate_change: Decimal.new("0.00"),
        ownership_changes: [
          %{entity_name: "Founder", new_percentage: Decimal.new("85.00")},
          %{entity_name: "Angel Investor", new_percentage: Decimal.new("15.00")}
        ],
        exit_type: :none
      }

      state_after_angel = Engine.apply_outcome(game_state, outcome1, "accept angel")

      # Second round: VC investment
      outcome2 = %{
        text: "VC firm invests in the company",
        cash_change: Decimal.new("500000.00"),
        burn_rate_change: Decimal.new("5000.00"),
        ownership_changes: [
          %{entity_name: "Founder", new_percentage: Decimal.new("60.00")},
          %{entity_name: "Angel Investor", new_percentage: Decimal.new("10.00")},
          %{entity_name: "VC Firm", new_percentage: Decimal.new("30.00")}
        ],
        exit_type: :none
      }

      state_after_vc = Engine.apply_outcome(state_after_angel, outcome2, "accept vc")

      # Verify final ownership structure
      assert length(state_after_vc.ownerships) == 3

      founder = Enum.find(state_after_vc.ownerships, fn o -> o.entity_name == "Founder" end)
      angel = Enum.find(state_after_vc.ownerships, fn o -> o.entity_name == "Angel Investor" end)
      vc = Enum.find(state_after_vc.ownerships, fn o -> o.entity_name == "VC Firm" end)

      assert Decimal.equal?(founder.percentage, Decimal.new("60.00"))
      assert Decimal.equal?(angel.percentage, Decimal.new("10.00"))
      assert Decimal.equal?(vc.percentage, Decimal.new("30.00"))

      # Verify financial changes
      # 10000 + 100000 + 500000 - 1000 - 6000 (burn rate)
      assert Decimal.equal?(state_after_vc.cash_on_hand, Decimal.new("603000.00"))
      # 1000 + 5000
      assert Decimal.equal?(state_after_vc.burn_rate, Decimal.new("6000.00"))
    end

    test "handles dilution with employee stock options" do
      # Create initial game state with VC investment
      game_state = Engine.new_game("Test Startup", "A test startup", StaticScenarioProvider)

      # First round: VC investment
      outcome1 = %{
        text: "VC firm invests in the company",
        cash_change: Decimal.new("500000.00"),
        burn_rate_change: Decimal.new("5000.00"),
        ownership_changes: [
          %{entity_name: "Founder", new_percentage: Decimal.new("70.00")},
          %{entity_name: "VC Firm", new_percentage: Decimal.new("30.00")}
        ],
        exit_type: :none
      }

      state_after_vc = Engine.apply_outcome(game_state, outcome1, "accept vc")

      # Second round: Employee stock options
      outcome2 = %{
        text: "Employee stock options are issued",
        cash_change: Decimal.new("0.00"),
        burn_rate_change: Decimal.new("0.00"),
        ownership_changes: [
          %{entity_name: "Founder", new_percentage: Decimal.new("63.00")},
          %{entity_name: "VC Firm", new_percentage: Decimal.new("27.00")},
          %{entity_name: "Employee Pool", new_percentage: Decimal.new("10.00")}
        ],
        exit_type: :none
      }

      state_after_options = Engine.apply_outcome(state_after_vc, outcome2, "issue options")

      # Verify final ownership structure
      assert length(state_after_options.ownerships) == 3

      founder = Enum.find(state_after_options.ownerships, fn o -> o.entity_name == "Founder" end)
      vc = Enum.find(state_after_options.ownerships, fn o -> o.entity_name == "VC Firm" end)

      pool =
        Enum.find(state_after_options.ownerships, fn o -> o.entity_name == "Employee Pool" end)

      assert Decimal.equal?(founder.percentage, Decimal.new("63.00"))
      assert Decimal.equal?(vc.percentage, Decimal.new("27.00"))
      assert Decimal.equal?(pool.percentage, Decimal.new("10.00"))
    end

    test "handles exit event with ownership changes" do
      # Create initial game state with multiple investors
      game_state = Engine.new_game("Test Startup", "A test startup", StaticScenarioProvider)

      # Set up initial ownership structure
      outcome1 = %{
        text: "Multiple investors join the company",
        cash_change: Decimal.new("1000000.00"),
        burn_rate_change: Decimal.new("10000.00"),
        ownership_changes: [
          %{entity_name: "Founder", new_percentage: Decimal.new("50.00")},
          %{entity_name: "Angel Investor", new_percentage: Decimal.new("20.00")},
          %{entity_name: "VC Firm", new_percentage: Decimal.new("30.00")}
        ],
        exit_type: :none
      }

      state_after_investment = Engine.apply_outcome(game_state, outcome1, "accept investments")

      # Simulate acquisition exit
      outcome2 = %{
        text: "Company is acquired",
        cash_change: Decimal.new("0.00"),
        burn_rate_change: Decimal.new("0.00"),
        ownership_changes: [],
        exit_type: :acquisition,
        exit_value: Decimal.new("10000000.00")
      }

      final_state = Engine.apply_outcome(state_after_investment, outcome2, "accept acquisition")

      # Verify game completed with acquisition
      assert final_state.status == :completed
      assert final_state.exit_type == :acquisition
      assert Decimal.equal?(final_state.exit_value, Decimal.new("10000000.00"))

      # Verify ownership structure remains unchanged
      assert length(final_state.ownerships) == 3

      founder = Enum.find(final_state.ownerships, fn o -> o.entity_name == "Founder" end)
      angel = Enum.find(final_state.ownerships, fn o -> o.entity_name == "Angel Investor" end)
      vc = Enum.find(final_state.ownerships, fn o -> o.entity_name == "VC Firm" end)

      assert Decimal.equal?(founder.percentage, Decimal.new("50.00"))
      assert Decimal.equal?(angel.percentage, Decimal.new("20.00"))
      assert Decimal.equal?(vc.percentage, Decimal.new("30.00"))
    end

    test "preserves existing ownership structure when no changes are specified" do
      # Create initial game state
      game_state = Engine.new_game("Test Startup", "A test startup", StaticScenarioProvider)

      # First set up an initial ownership structure with multiple investors
      outcome1 = %{
        text: "Multiple investors join the company",
        cash_change: Decimal.new("1000000.00"),
        burn_rate_change: Decimal.new("10000.00"),
        ownership_changes: [
          %{entity_name: "Founder", new_percentage: Decimal.new("50.00")},
          %{entity_name: "Angel Investor", new_percentage: Decimal.new("20.00")},
          %{entity_name: "VC Firm", new_percentage: Decimal.new("30.00")}
        ],
        exit_type: :none
      }

      state_after_investment = Engine.apply_outcome(game_state, outcome1, "accept investments")

      # Create an outcome with no ownership changes
      outcome2 = %{
        text: "Company hires new employees",
        # Hiring costs
        cash_change: Decimal.new("-50000.00"),
        # Increased monthly costs
        burn_rate_change: Decimal.new("5000.00"),
        # No ownership changes
        ownership_changes: [],
        exit_type: :none
      }

      # Apply the outcome
      updated_state = Engine.apply_outcome(state_after_investment, outcome2, "hire employees")

      # Verify ownership structure remains exactly the same
      assert length(updated_state.ownerships) == 3

      founder = Enum.find(updated_state.ownerships, fn o -> o.entity_name == "Founder" end)
      angel = Enum.find(updated_state.ownerships, fn o -> o.entity_name == "Angel Investor" end)
      vc = Enum.find(updated_state.ownerships, fn o -> o.entity_name == "VC Firm" end)

      assert Decimal.equal?(founder.percentage, Decimal.new("50.00"))
      assert Decimal.equal?(angel.percentage, Decimal.new("20.00"))
      assert Decimal.equal?(vc.percentage, Decimal.new("30.00"))
    end

    test "preserves unmentioned owners when applying partial ownership changes" do
      # Create initial game state
      game_state = Engine.new_game("Test Startup", "A test startup", StaticScenarioProvider)

      # First set up an initial ownership structure with multiple investors
      outcome1 = %{
        text: "Multiple investors join the company",
        cash_change: Decimal.new("1000000.00"),
        burn_rate_change: Decimal.new("10000.00"),
        ownership_changes: [
          %{entity_name: "Founder", new_percentage: Decimal.new("50.00")},
          %{entity_name: "Angel Investor", new_percentage: Decimal.new("20.00")},
          %{entity_name: "VC Firm", new_percentage: Decimal.new("30.00")}
        ],
        exit_type: :none
      }

      state_after_investment = Engine.apply_outcome(game_state, outcome1, "accept investments")

      # Create an outcome that only mentions some of the current owners
      outcome2 = %{
        text: "Founder sells some shares to new investor",
        cash_change: Decimal.new("0.00"),
        burn_rate_change: Decimal.new("0.00"),
        ownership_changes: [
          %{entity_name: "Founder", new_percentage: Decimal.new("40.00")},
          %{entity_name: "New Investor", new_percentage: Decimal.new("10.00")}
        ],
        exit_type: :none
      }

      # Apply the outcome
      updated_state = Engine.apply_outcome(state_after_investment, outcome2, "sell shares")

      # Verify all owners are present and percentages are correct
      assert length(updated_state.ownerships) == 4

      founder = Enum.find(updated_state.ownerships, fn o -> o.entity_name == "Founder" end)
      angel = Enum.find(updated_state.ownerships, fn o -> o.entity_name == "Angel Investor" end)
      vc = Enum.find(updated_state.ownerships, fn o -> o.entity_name == "VC Firm" end)

      new_investor =
        Enum.find(updated_state.ownerships, fn o -> o.entity_name == "New Investor" end)

      # Verify percentages for all owners
      assert Decimal.equal?(founder.percentage, Decimal.new("40.00"))
      assert Decimal.equal?(angel.percentage, Decimal.new("20.00"))
      assert Decimal.equal?(vc.percentage, Decimal.new("30.00"))
      assert Decimal.equal?(new_investor.percentage, Decimal.new("10.00"))

      # Verify total ownership adds up to 100%
      total_percentage =
        Enum.reduce(updated_state.ownerships, Decimal.new("0.00"), fn owner, acc ->
          Decimal.add(acc, owner.percentage)
        end)

      assert Decimal.equal?(total_percentage, Decimal.new("100.00"))
    end
  end
end
