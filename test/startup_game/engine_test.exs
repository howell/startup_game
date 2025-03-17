defmodule StartupGame.EngineTest do
  use ExUnit.Case

  alias StartupGame.Engine
  alias StartupGame.Engine.GameState
  alias StartupGame.Engine.GameRunner

  describe "simplified engine" do
    test "creates a new game with initial state" do
      game_state = Engine.new_game("Test Startup", "A test startup")

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
      game_state = Engine.new_game("Test Startup", "A test startup")

      # Accept angel investment
      updated_state = Engine.process_choice(game_state, "accept")

      # Check that cash was updated
      assert Decimal.equal?(updated_state.cash_on_hand, Decimal.new("110000.00"))

      # Check that ownership was updated
      assert length(updated_state.ownerships) == 2
      founder = Enum.find(updated_state.ownerships, fn o -> o.entity_name == "Founder" end)
      investor = Enum.find(updated_state.ownerships, fn o -> o.entity_name == "Angel Investor" end)
      assert Decimal.equal?(founder.percentage, Decimal.new("85.00"))
      assert Decimal.equal?(investor.percentage, Decimal.new("15.00"))

      # Check that round was recorded
      assert length(updated_state.rounds) == 1
      assert hd(updated_state.rounds).scenario_id == "angel_investment"
      assert hd(updated_state.rounds).response == "Accept the offer as is"

      # Check that next scenario was set
      assert updated_state.current_scenario == "hiring_decision"
    end

    test "completes a game with acquisition" do
      # Run a complete game with predefined choices
      final_state = GameRunner.run_game(
        "Test Startup",
        "A test startup",
        ["accept", "experienced", "settle", "accept"]
      )

      # Check that game was completed with acquisition
      assert final_state.status == :completed
      assert final_state.exit_type == :acquisition
      assert Decimal.equal?(final_state.exit_value, Decimal.new("2000000.00"))
      assert length(final_state.rounds) == 4
    end

    test "fails a game due to running out of money" do
      # Run a game that will fail
      final_state = GameRunner.run_game(
        "Test Startup",
        "A test startup",
        ["decline", "experienced", "fight"]
      )

      # Check that game failed
      assert final_state.status == :failed
      assert final_state.exit_type == :shutdown

      # Check that cash is negative or runway is insufficient
      assert Decimal.compare(final_state.cash_on_hand, Decimal.new("0")) == :lt ||
             Decimal.compare(GameState.calculate_runway(final_state), Decimal.new("1")) == :lt
    end
  end
end
