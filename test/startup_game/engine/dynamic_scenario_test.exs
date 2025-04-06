defmodule StartupGame.Engine.DynamicScenarioTest do
  use ExUnit.Case, async: true

  alias StartupGame.Engine
  alias StartupGame.Engine.Demo.{DynamicScenarioProvider, StaticScenarioProvider}

  describe "dynamic scenario provider" do
    test "creates a game with dynamic scenario provider" do
      # Create game without initial scenario
      game = Engine.new_game("TechNova", "AI-powered project management", DynamicScenarioProvider)

      # Set the initial scenario
      game = Engine.set_next_scenario(game)

      assert game.name == "TechNova"
      assert game.description == "AI-powered project management"
      assert game.scenario_provider == DynamicScenarioProvider
      assert game.current_scenario != nil
      assert game.current_scenario_data != nil
      assert String.starts_with?(game.current_scenario, "dynamic_")
    end

    test "processes a choice with dynamic scenario provider" do
      # Create game without initial scenario
      game = Engine.new_game("TechNova", "AI-powered project management", DynamicScenarioProvider)

      # Set the initial scenario
      game = Engine.set_next_scenario(game)

      updated_game = Engine.process_player_input(game, "accept")

      # Check that the round was added
      assert length(updated_game.rounds) == 1
      round = List.first(updated_game.rounds)

      # Verify the response was recorded
      assert round.player_input == "accept"

      # Verify the outcome contains part of the response text
      assert String.contains?(round.outcome, "accept")
    end
  end

  describe "static scenario provider" do
    test "creates a game with static scenario provider" do
      # Create game without initial scenario
      game = Engine.new_game("TechNova", "AI-powered project management", StaticScenarioProvider)

      # Set the initial scenario
      game = Engine.set_next_scenario(game)

      assert game.name == "TechNova"
      assert game.description == "AI-powered project management"
      assert game.scenario_provider == StaticScenarioProvider
      assert game.current_scenario == "angel_investment"
      assert game.current_scenario_data != nil
    end

    test "processes a choice with static scenario provider" do
      # Create game without initial scenario
      game = Engine.new_game("TechNova", "AI-powered project management", StaticScenarioProvider)

      # Set the initial scenario
      game = Engine.set_next_scenario(game)

      # Process a choice
      updated_game = Engine.process_player_input(game, "accept")

      # Check that the round was added
      assert length(updated_game.rounds) == 1

      updated_game = Engine.set_next_scenario(updated_game)

      # Verify the next scenario is from the static sequence
      assert updated_game.current_scenario == "hiring_decision"
    end
  end
end
