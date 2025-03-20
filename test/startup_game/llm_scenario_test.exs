defmodule StartupGame.LLMScenarioTest do
  use ExUnit.Case, async: true

  alias StartupGame.Engine
  alias StartupGame.Engine.{GameState, Scenario, LLMScenarioProvider}

  describe "LLM Scenario Provider is able to generate a situation" do
    setup do
      game = Engine.new_game("TechNova", "AI-powered project management", LLMScenarioProvider)
      {:ok, game: game}
    end

    @tag skip: "This test hits the LLM API incurring a cost. Run it manually if desired."
    test "generates a situation", %{game: game} do
      situation = LLMScenarioProvider.get_next_scenario(game, nil)
      assert situation.situation != nil
    end
  end

  describe "LLM Scenario Provider is able to generate an outcome" do
    setup do
      game = Engine.new_game("Chlip", "Edible paper clips", LLMScenarioProvider)
      situation_id = "dynamic_123"

      situation = """
      As Chlip's edible paper clips start to gain some early traction, a concerning article is published in a major newspaper with the headline "Are Edible Office Supplies Safe? Health Experts Raise Concerns".

      The article quotes several nutritionists and health experts who question the safety and nutritional value of regularly consuming office supplies like paper clips, even if they are technically edible. One expert is quoted as saying "Just because something can be eaten doesn't mean it should be. Encouraging people, especially office workers, to snack on metal clips could lead to unintended health consequences."

      While none of the claims are substantiated with hard evidence, and no one has reported actually being harmed by your product, the article is starting to gain traction on social media and raising questions among some of your early customers and retail partners.

      How do you want to respond to this potential PR crisis for your young company?
      """

      {:ok,
       game: %GameState{
         game
         | current_scenario: situation_id,
           current_scenario_data: %Scenario{id: situation_id, type: :legal, situation: situation}
       }}
    end

    @tag skip: "This test hits the LLM API incurring a cost. Run it manually if desired."
    test "generates an outcome", %{game: game} do
      choice = "I want to bribe doctors to promote the health benefits of Chlip products"
      result = LLMScenarioProvider.generate_outcome(game, game.current_scenario_data, choice)
      assert {:ok, outcome} = result
      assert Map.has_key?(outcome, :text)
      assert Map.has_key?(outcome, :cash_change)
      assert Map.has_key?(outcome, :burn_rate_change)
      assert Map.has_key?(outcome, :ownership_changes)
      assert Map.has_key?(outcome, :exit_type)
    end
  end
end
