defmodule StartupGame.LLMScenarioTest do
  use ExUnit.Case, async: true

  alias StartupGame.Engine
  alias StartupGame.Engine.LLMScenarioProvider

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
end
