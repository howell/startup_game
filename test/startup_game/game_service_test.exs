defmodule StartupGame.GameServiceTest do
  use StartupGame.DataCase

  alias StartupGame.GameService
  alias StartupGame.Games
  alias StartupGame.Engine.Demo.StaticScenarioProvider
  alias StartupGame.AccountsFixtures

  describe "start_game/4" do
    setup do
      user = AccountsFixtures.user_fixture()
      %{user: user}
    end

    test "creates a new game with database record", %{user: user} do
      {:ok, %{game: game, game_state: game_state}} =
        GameService.start_game("Test Startup", "Testing", user, StaticScenarioProvider)

      assert game.name == "Test Startup"
      assert game.description == "Testing"
      assert game_state.name == "Test Startup"
      assert game_state.description == "Testing"
    end

    test "initializes with correct default values", %{user: user} do
      {:ok, %{game: game, game_state: game_state}} =
        GameService.start_game("Test Startup", "Testing", user, StaticScenarioProvider)

      assert Decimal.compare(game.cash_on_hand, Decimal.new("10000.00")) == :eq
      assert Decimal.compare(game.burn_rate, Decimal.new("1000.00")) == :eq
      assert game.status == :in_progress
      assert game_state.status == :in_progress
    end

    test "creates initial round with scenario", %{user: user} do
      {:ok, %{game: game}} =
        GameService.start_game("Test Startup", "Testing", user, StaticScenarioProvider)

      rounds = Games.list_game_rounds(game.id)
      assert length(rounds) == 1
      [first_round] = rounds
      assert first_round.situation != nil
    end
  end

  describe "load_game/1" do
    setup do
      user = AccountsFixtures.user_fixture()
      {:ok, %{game: game}} = GameService.start_game("Test Startup", "Testing", user, StaticScenarioProvider)

      %{user: user, game: game}
    end

    test "loads game from database", %{game: game} do
      {:ok, %{game: loaded_game, game_state: game_state}} =
        GameService.load_game(game.id)

      assert loaded_game.id == game.id
      assert game_state.name == "Test Startup"
      assert game_state.scenario_provider == StaticScenarioProvider
    end

    test "builds game state with proper structure", %{game: game} do
      {:ok, %{game_state: game_state}} = GameService.load_game(game.id)

      assert game_state.cash_on_hand != nil
      assert game_state.burn_rate != nil
      assert game_state.status == :in_progress
      assert game_state.current_scenario != nil
      assert game_state.current_scenario_data != nil
    end
  end

  describe "process_response/2" do
    setup do
      user = AccountsFixtures.user_fixture()
      {:ok, %{game: game}} = GameService.start_game("Test Startup", "Testing", user, StaticScenarioProvider)

      %{user: user, game: game}
    end

    test "processes response and creates new round", %{game: game} do
      {:ok, %{game: updated_game}} =
        GameService.process_response(game.id, "I'll focus on product development")

      rounds = Games.list_game_rounds(updated_game.id)
      assert length(rounds) == 2

      # Check the most recent round
      [_first, second] = Enum.sort_by(rounds, & &1.inserted_at)
      assert second.response == "I'll focus on product development"
      assert second.outcome != nil
    end

    test "updates game state after response", %{game: game} do
      initial_cash = game.cash_on_hand

      {:ok, %{game: updated_game}} =
        GameService.process_response(game.id, "I'll focus on product development")

      # Game state should be updated (either cash or burn rate might change)
      assert updated_game.cash_on_hand != initial_cash ||
             updated_game.burn_rate != game.burn_rate
    end
  end
end
