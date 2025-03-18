defmodule StartupGame.Engine.DynamicScenarioTest do
  use ExUnit.Case, async: true

  alias StartupGame.Engine
  alias StartupGame.Engine.Demo.{DynamicScenarioProvider, StaticScenarioProvider}

  describe "dynamic scenario provider" do
    test "creates a game with dynamic scenario provider" do
      game = Engine.new_game("TechNova", "AI-powered project management", DynamicScenarioProvider)

      assert game.name == "TechNova"
      assert game.description == "AI-powered project management"
      assert game.scenario_provider == DynamicScenarioProvider
      assert game.current_scenario != nil
      assert game.current_scenario_data != nil
      assert String.starts_with?(game.current_scenario, "dynamic_")
    end

    test "processes a choice with dynamic scenario provider" do
      game = Engine.new_game("TechNova", "AI-powered project management", DynamicScenarioProvider)

      # Process a choice with a response text
      response_text =
        "I'd like to accept your offer, but I want to ensure we have a good working relationship."

      updated_game = Engine.process_choice(game, "accept", response_text)

      # Check that the round was added
      assert length(updated_game.rounds) == 1
      round = List.first(updated_game.rounds)

      # Verify the response was recorded
      assert round.response == response_text

      # Verify the outcome contains part of the response text
      assert String.contains?(round.outcome, String.slice(response_text, 0, 30))

      # Verify a new scenario was generated
      assert updated_game.current_scenario != game.current_scenario
      assert updated_game.current_scenario_data != nil
    end

    test "ends the game after 5 rounds" do
      game = Engine.new_game("TechNova", "AI-powered project management", DynamicScenarioProvider)

      # Process 5 choices to reach the end of the game
      game =
        Enum.reduce(1..5, game, fn _, acc ->
          Engine.process_choice(acc, "accept", "I accept this offer.")
        end)

      # Verify the game has ended
      assert game.status == :completed
      assert game.current_scenario == nil
      assert game.current_scenario_data == nil
      assert length(game.rounds) == 5
    end
  end

  describe "static scenario provider" do
    test "creates a game with static scenario provider" do
      game = Engine.new_game("TechNova", "AI-powered project management", StaticScenarioProvider)

      assert game.name == "TechNova"
      assert game.description == "AI-powered project management"
      assert game.scenario_provider == StaticScenarioProvider
      assert game.current_scenario == "angel_investment"
      assert game.current_scenario_data != nil
    end

    test "processes a choice with static scenario provider" do
      game = Engine.new_game("TechNova", "AI-powered project management", StaticScenarioProvider)

      # Process a choice
      updated_game = Engine.process_choice(game, "accept")

      # Check that the round was added
      assert length(updated_game.rounds) == 1

      # Verify the next scenario is from the static sequence
      assert updated_game.current_scenario == "hiring_decision"
    end
  end
end
