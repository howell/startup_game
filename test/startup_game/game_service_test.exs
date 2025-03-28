defmodule StartupGame.GameServiceTest do
  use StartupGame.DataCase

  alias StartupGame.GameService
  alias StartupGame.Games
  alias StartupGame.Engine.Demo.StaticScenarioProvider
  alias StartupGame.AccountsFixtures
  alias StartupGame.Engine.GameState

  describe "start_game/4" do
    setup do
      user = AccountsFixtures.user_fixture()
      %{user: user}
    end

    test "creates a new game with database record", %{user: user} do
      {:ok, %{game: game, game_state: game_state}} =
        GameService.create_and_start_game("Test Startup", "Testing", user, StaticScenarioProvider)

      assert game.name == "Test Startup"
      assert game.description == "Testing"
      assert game_state.name == "Test Startup"
      assert game_state.description == "Testing"
    end

    test "initializes with correct default values", %{user: user} do
      {:ok, %{game: game, game_state: game_state}} =
        GameService.create_and_start_game("Test Startup", "Testing", user, StaticScenarioProvider)

      assert Decimal.compare(game.cash_on_hand, Decimal.new("10000.00")) == :eq
      assert Decimal.compare(game.burn_rate, Decimal.new("1000.00")) == :eq
      assert game.status == :in_progress
      assert game_state.status == :in_progress
    end

    test "creates initial round with scenario", %{user: user} do
      {:ok, %{game: game}} =
        GameService.create_and_start_game("Test Startup", "Testing", user, StaticScenarioProvider)

      rounds = Games.list_game_rounds(game.id)
      assert length(rounds) == 1
      [first_round] = rounds
      assert first_round.situation != nil
    end

    test "should respect is_public and is_leaderboard_eligible preferences", %{user: user} do
      # Create game with public and leaderboard eligible attributes
      {:ok, %{game: game}} =
        GameService.create_game(
          "Public Startup",
          "Testing public visibility",
          user,
          StaticScenarioProvider,
          %{is_public: true, is_leaderboard_eligible: true}
        )

      # Verify that these values are respected
      assert game.is_public == true
      assert game.is_leaderboard_eligible == true

      # Create another game with default values
      {:ok, %{game: default_game}} =
        GameService.create_game(
          "Default Startup",
          "Testing default visibility",
          user,
          StaticScenarioProvider
        )

      # Verify defaults are false
      assert default_game.is_public == false
      assert default_game.is_leaderboard_eligible == false
    end

    test "should respect user's default_game_visibility preference" do
      user = AccountsFixtures.user_fixture(%{default_game_visibility: :public})

      {:ok, %{game: game}} =
        GameService.create_and_start_game("Test Startup", "Testing", user, StaticScenarioProvider)

      assert game.is_public == true
      assert game.is_leaderboard_eligible == true
    end
  end

  describe "load_game/1" do
    setup do
      user = AccountsFixtures.user_fixture()

      {:ok, %{game: game}} =
        GameService.create_and_start_game("Test Startup", "Testing", user, StaticScenarioProvider)

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

    test "returns error for non-existent game" do
      non_existent_id = Ecto.UUID.generate()
      result = GameService.load_game(non_existent_id)

      assert result == {:error, "Game not found"}
    end

    test "loads all rounds associated with the game", %{game: game} do
      # First add a response to create another round
      {:ok, %{game: updated_game}} = GameService.process_response(game.id, "accept")

      # Now load the game and check both rounds are included
      {:ok, %{game: game, game_state: game_state}} = GameService.load_game(updated_game.id)

      assert length(game.rounds) == 2
      assert length(game_state.rounds) == 1

      [first_round, second_round] = game.rounds

      assert first_round.situation =~ "An angel investor offers"
      assert first_round.response == "accept"
      assert first_round.outcome != nil
      assert second_round.situation =~ "You need to hire a key employee"

      # The game_state's rounds will only contain completed rounds
      gs_round = hd(game_state.rounds)
      assert gs_round.situation =~ "An angel investor offers"
      assert gs_round.response == "accept"
      assert gs_round.outcome != nil

      # The current scenario data should be about the hiring scenario
      assert game_state.current_scenario_data.situation =~ "You need to hire a key employee"
    end

    test "loads game ownerships correctly", %{game: game} do
      # Process a response that changes ownership
      {:ok, %{game: updated_game}} = GameService.process_response(game.id, "accept")

      # Now load the game and check ownerships
      {:ok, %{game_state: game_state}} = GameService.load_game(updated_game.id)

      # The angel investment scenario should have changed ownership
      assert length(game_state.ownerships) == 2

      founder = Enum.find(game_state.ownerships, &(&1.entity_name == "Founder"))
      investor = Enum.find(game_state.ownerships, &(&1.entity_name == "Angel Investor"))

      assert founder != nil
      assert investor != nil
      assert Decimal.compare(founder.percentage, Decimal.new("85.00")) == :eq
      assert Decimal.compare(investor.percentage, Decimal.new("15.00")) == :eq
    end
  end

  describe "process_response/2" do
    setup do
      user = AccountsFixtures.user_fixture()

      {:ok, %{game: game}} =
        GameService.create_and_start_game("Test Startup", "Testing", user, StaticScenarioProvider)

      %{user: user, game: game}
    end

    test "processes response and creates new round", %{game: game} do
      {:ok, %{game: updated_game}} =
        GameService.process_response(game.id, "accept")

      rounds = Games.list_game_rounds(updated_game.id)
      assert length(rounds) == 2

      # Check the most recent round
      [first, second] = Enum.sort_by(rounds, & &1.inserted_at)
      assert first.response == "accept"
      assert first.outcome != nil
      assert first.situation != second.situation
    end

    test "updates game state after response", %{game: game} do
      initial_cash = game.cash_on_hand

      {:ok, %{game: updated_game}} =
        GameService.process_response(game.id, "accept")

      # Game state should be updated (either cash or burn rate might change)
      assert updated_game.cash_on_hand != initial_cash ||
               updated_game.burn_rate != game.burn_rate
    end

    test "returns error for non-existent game" do
      non_existent_id = Ecto.UUID.generate()
      result = GameService.process_response(non_existent_id, "accept")

      assert result == {:error, "Game not found"}
    end

    test "processes response that changes cash_on_hand", %{game: game} do
      # 'settle' will cost $50,000 in the lawsuit scenario
      # We need to step through scenarios to get to the lawsuit
      # angel investment
      {:ok, %{game: updated_game}} = GameService.process_response(game.id, "accept")
      # hiring
      {:ok, %{game: updated_game}} = GameService.process_response(updated_game.id, "experienced")

      # Capture initial cash before responding to lawsuit
      initial_burn_rate = updated_game.burn_rate
      initial_cash = Decimal.sub(updated_game.cash_on_hand, initial_burn_rate)

      # Now respond to lawsuit with 'settle' - use 's' since that's the selection key
      {:ok, %{game: final_game}} = GameService.process_response(updated_game.id, "settle")

      # Verify cash change is -50000.00
      expected_cash = Decimal.sub(initial_cash, Decimal.new("50000.00"))
      assert Decimal.compare(final_game.cash_on_hand, expected_cash) == :eq
    end

    test "processes response that changes burn_rate", %{game: game} do
      # 'experienced' should increase burn rate by $3,000
      # First handle angel investment to get to hiring scenario
      {:ok, %{game: updated_game}} = GameService.process_response(game.id, "accept")

      initial_burn_rate = updated_game.burn_rate

      # Now respond to hiring with 'experienced'
      {:ok, %{game: final_game}} = GameService.process_response(updated_game.id, "experienced")

      # Verify burn rate change is +3000.00
      expected_burn_rate = Decimal.add(initial_burn_rate, Decimal.new("3000.00"))
      assert Decimal.compare(final_game.burn_rate, expected_burn_rate) == :eq
    end

    test "processes response that changes ownership structure", %{game: game} do
      # Initial ownership should be 100% founder
      ownerships = Games.list_game_ownerships(game.id)
      assert length(ownerships) == 1
      [founder] = ownerships
      assert founder.entity_name == "Founder"
      assert Decimal.compare(founder.percentage, Decimal.new("100.00")) == :eq

      # Process 'accept' response to angel investment scenario
      {:ok, %{game: updated_game}} = GameService.process_response(game.id, "accept")

      # Verify ownership structure changed
      updated_ownerships = Games.list_game_ownerships(updated_game.id)
      assert length(updated_ownerships) == 2

      # Find founder and investor in the list
      founder = Enum.find(updated_ownerships, &(&1.entity_name == "Founder"))
      investor = Enum.find(updated_ownerships, &(&1.entity_name == "Angel Investor"))

      assert founder != nil
      assert investor != nil
      assert Decimal.compare(founder.percentage, Decimal.new("85.00")) == :eq
      assert Decimal.compare(investor.percentage, Decimal.new("15.00")) == :eq
    end

    test "processes response that triggers game exit", %{game: game} do
      # Need to get through three scenarios to reach acquisition scenario
      # angel investment
      {:ok, %{game: game2}} = GameService.process_response(game.id, "accept")
      # hiring
      {:ok, %{game: game3}} = GameService.process_response(game2.id, "experienced")
      # lawsuit
      {:ok, %{game: game4}} = GameService.process_response(game3.id, "settle")

      # Now process response to acquisition scenario with 'accept'
      {:ok, %{game: final_game}} = GameService.process_response(game4.id, "accept")

      # Verify game status and exit details
      assert final_game.status == :completed
      assert final_game.exit_type == :acquisition
      assert Decimal.compare(final_game.exit_value, Decimal.new("2000000.00")) == :eq
    end
  end

  describe "start_next_round/2" do
    setup do
      user = AccountsFixtures.user_fixture()

      {:ok, %{game: game, game_state: game_state}} =
        GameService.create_and_start_game("Test Startup", "Testing", user, StaticScenarioProvider)

      %{user: user, game: game, game_state: game_state}
    end

    test "sets next scenario correctly", %{game: game, game_state: game_state} do
      # First process a response to update the game state
      updated_game_state = %GameState{
        game_state
        | rounds: [
            %{
              scenario_id: "angel_investment",
              situation: "An angel investor offers $100,000 for 15% of your company.",
              response: "accept",
              outcome: "You accept the offer and receive the investment.",
              cash_change: Decimal.new("100000.00"),
              burn_rate_change: Decimal.new("0.00"),
              ownership_changes: nil
            }
          ],
          current_scenario: "angel_investment"
      }

      # Call start_next_round with the updated game_state
      {:ok, %{game_state: new_game_state}} =
        GameService.start_next_round(game, updated_game_state)

      # Verify new scenario was set correctly - should be "hiring_decision"
      assert new_game_state.current_scenario == "hiring_decision"
      assert new_game_state.current_scenario_data != nil
      assert new_game_state.current_scenario_data.situation =~ "You need to hire a key employee"
    end

    test "creates a new round in the database", %{game: game, game_state: game_state} do
      # Count initial rounds
      initial_rounds = Games.list_game_rounds(game.id)
      initial_count = length(initial_rounds)

      # Set a specific current scenario to control what comes next
      updated_game_state = %GameState{
        game_state
        | current_scenario: "angel_investment"
      }

      # Call start_next_round
      {:ok, _} = GameService.start_next_round(game, updated_game_state)

      # Verify a new round was created
      updated_rounds = Games.list_game_rounds(game.id)
      assert length(updated_rounds) == initial_count + 1

      # Verify the content of the new round
      newest_round = Enum.max_by(updated_rounds, & &1.inserted_at)
      assert newest_round.situation =~ "You need to hire a key employee"
      assert newest_round.response == nil
      assert newest_round.outcome == nil
    end

    test "handles error when failing to generate next scenario", %{game: game} do
      # Create a game state with a completed status, which should prevent new scenarios
      game_state = %GameState{
        name: "Test Startup",
        description: "Testing",
        cash_on_hand: Decimal.new("10000.00"),
        burn_rate: Decimal.new("1000.00"),
        # This should prevent new scenarios
        status: :completed,
        rounds: [],
        current_scenario: nil,
        scenario_provider: StaticScenarioProvider
      }

      # Call start_next_round with this game state
      result = GameService.start_next_round(game, game_state)

      # Should return an error
      assert result == {:error, "Failed to generate next scenario"}
    end
  end

  describe "sequence steps from static provider correctly" do
    setup do
      user = AccountsFixtures.user_fixture()

      {:ok, %{game: game}} =
        GameService.create_and_start_game("Test Startup", "Testing", user, StaticScenarioProvider)

      %{user: user, game: game}
    end

    test "processes responses in sequence", %{game: game} do
      {:ok, %{game: updated_game}} =
        GameService.process_response(game.id, "accept")

      {:ok, %{game: updated_game}} =
        GameService.process_response(updated_game.id, "experienced")

      # Using 's' for 'settle'
      {:ok, %{game: updated_game}} =
        GameService.process_response(updated_game.id, "s")

      rounds = Games.list_game_rounds(updated_game.id)
      assert length(rounds) == 4

      # Check all rounds in order
      sorted_rounds = Enum.sort_by(rounds, & &1.inserted_at)
      [first, second, third, fourth] = sorted_rounds

      assert first.situation =~ "An angel investor offers"
      assert first.response == "accept"
      assert first.outcome =~ "You accept the offer and receive the investment"

      assert second.situation =~ "You need to hire a key employee"
      assert second.response == "experienced"
      assert second.outcome =~ "The experienced developer brings immediate value"

      assert third.situation =~ "Your startup has been sued"
      # This matches what we sent
      assert third.response == "s"
      assert third.outcome =~ "You settle the lawsuit for $50,000"

      assert fourth.situation =~ "A larger company offers to acquire your startup"
      assert fourth.response == nil
    end

    test "processes full game lifecycle through acquisition exit", %{game: game} do
      # Process all four scenarios with responses that lead to acquisition
      # angel investment
      {:ok, %{game: game2}} = GameService.process_response(game.id, "accept")
      # hiring
      {:ok, %{game: game3}} = GameService.process_response(game2.id, "experienced")
      # lawsuit
      {:ok, %{game: game4}} = GameService.process_response(game3.id, "settle")
      # acquisition
      {:ok, %{game: final_game}} = GameService.process_response(game4.id, "accept")

      # Verify final game state
      assert final_game.status == :completed
      assert final_game.exit_type == :acquisition
      assert Decimal.compare(final_game.exit_value, Decimal.new("2000000.00")) == :eq

      # Check that all rounds were created and have proper responses/outcomes
      rounds = Games.list_game_rounds(final_game.id)
      assert length(rounds) == 4

      # All rounds should have responses and outcomes
      for round <- Enum.sort_by(rounds, & &1.inserted_at) |> Enum.take(4) do
        assert round.response != nil
        assert round.outcome != nil
      end
    end
  end

  describe "save_round_result (through process_response)" do
    setup do
      user = AccountsFixtures.user_fixture()

      {:ok, %{game: game}} =
        GameService.create_and_start_game("Test Startup", "Testing", user, StaticScenarioProvider)

      %{user: user, game: game}
    end

    test "saves response and outcome to the round", %{game: game} do
      # First process a response
      {:ok, %{game: updated_game}} = GameService.process_response(game.id, "accept")

      # Verify the round was updated correctly
      rounds = Games.list_game_rounds(updated_game.id)
      sorted_rounds = Enum.sort_by(rounds, & &1.inserted_at)
      [first_round, _] = sorted_rounds

      assert first_round.response == "accept"
      assert first_round.outcome =~ "You accept the offer and receive the investment"
      assert Decimal.compare(first_round.cash_change, Decimal.new("100000.00")) == :eq
      assert Decimal.compare(first_round.burn_rate_change, Decimal.new("0.00")) == :eq
    end

    test "handles ownership changes correctly", %{game: game} do
      # Initial ownership should be 100% founder
      initial_ownerships = Games.list_game_ownerships(game.id)
      assert length(initial_ownerships) == 1
      [founder] = initial_ownerships
      assert founder.entity_name == "Founder"
      assert Decimal.compare(founder.percentage, Decimal.new("100.00")) == :eq

      # Process angel investment with 'accept' response
      {:ok, %{game: updated_game}} = GameService.process_response(game.id, "accept")

      # Verify ownership changes were processed correctly
      updated_ownerships = Games.list_game_ownerships(updated_game.id)
      assert length(updated_ownerships) == 2

      # Check founder's new percentage
      updated_founder = Enum.find(updated_ownerships, &(&1.entity_name == "Founder"))
      assert Decimal.compare(updated_founder.percentage, Decimal.new("85.00")) == :eq

      # Check investor's percentage
      investor = Enum.find(updated_ownerships, &(&1.entity_name == "Angel Investor"))
      assert Decimal.compare(investor.percentage, Decimal.new("15.00")) == :eq

      # Check that ownership changes were recorded
      rounds = Games.list_game_rounds(updated_game.id)
      round = List.first(Enum.sort_by(rounds, & &1.inserted_at))
      ownership_changes = Games.list_round_ownership_changes(round.id)
      assert length(ownership_changes) == 2

      founder_change = Enum.find(ownership_changes, &(&1.entity_name == "Founder"))
      assert Decimal.compare(founder_change.previous_percentage, Decimal.new("100.00")) == :eq
      assert Decimal.compare(founder_change.new_percentage, Decimal.new("85.00")) == :eq

      investor_change = Enum.find(ownership_changes, &(&1.entity_name == "Angel Investor"))
      assert Decimal.compare(investor_change.previous_percentage, Decimal.new("0.00")) == :eq
      assert Decimal.compare(investor_change.new_percentage, Decimal.new("15.00")) == :eq
    end

    test "handles nil ownership changes correctly", %{game: game} do
      # Fast-forward to lawsuit (which has no ownership changes)
      # angel investment
      {:ok, %{game: game2}} = GameService.process_response(game.id, "accept")
      # hiring
      {:ok, %{game: game3}} = GameService.process_response(game2.id, "experienced")

      # Get ownership before lawsuit
      ownerships_before = Games.list_game_ownerships(game3.id)

      # Respond to lawsuit with 'settle'
      {:ok, %{game: final_game}} = GameService.process_response(game3.id, "settle")

      # Verify ownerships are unchanged
      ownerships_after = Games.list_game_ownerships(final_game.id)
      assert length(ownerships_before) == length(ownerships_after)

      # Verify no ownership changes were recorded
      rounds = Games.list_game_rounds(final_game.id)
      lawsuit_round = Enum.find(rounds, &(&1.response == "settle"))
      ownership_changes = Games.list_round_ownership_changes(lawsuit_round.id)
      assert ownership_changes == []
    end

    test "updates game status and exit information correctly", %{game: game} do
      # Process all scenarios to reach acquisition
      # angel investment
      {:ok, %{game: game2}} = GameService.process_response(game.id, "accept")
      # hiring
      {:ok, %{game: game3}} = GameService.process_response(game2.id, "experienced")
      # lawsuit
      {:ok, %{game: game4}} = GameService.process_response(game3.id, "settle")

      # Verify game is still in progress
      assert game4.status == :in_progress
      assert game4.exit_type == :none

      # Process acquisition with 'accept'
      {:ok, %{game: final_game}} = GameService.process_response(game4.id, "accept")

      # Verify game status and exit info were updated
      assert final_game.status == :completed
      assert final_game.exit_type == :acquisition
      assert Decimal.compare(final_game.exit_value, Decimal.new("2000000.00")) == :eq
    end

    test "handles non-existent games gracefully" do
      non_existent_id = Ecto.UUID.generate()
      result = GameService.process_response(non_existent_id, "accept")
      assert result == {:error, "Game not found"}
    end

    test "handles non-existent rounds gracefully", %{user: user} do
      # Create a game but don't start it (which would create a round)
      {:ok, empty_game} =
        Games.create_new_game(
          %{
            name: "Empty Game",
            description: "Game with no rounds",
            cash_on_hand: Decimal.new("10000.00"),
            burn_rate: Decimal.new("1000.00")
          },
          user
        )

      # Check that there are no rounds
      rounds = Games.list_game_rounds(empty_game.id)
      assert rounds == []

      # Try to process a response
      result = GameService.process_response(empty_game.id, "accept")

      # Should fail gracefully, not crash
      assert {:error, _} = result
    end

    test "processes invalid responses gracefully", %{game: game} do
      # Send a completely invalid response
      result = GameService.process_response(game.id, "xxxxxxxxx")

      # Should return error but not crash
      assert {:error, message} = result

      assert message =~ "Please try again"
    end

    test "completes financial transaction properly", %{game: game} do
      # Capture initial financial state
      initial_cash = game.cash_on_hand
      initial_burn = game.burn_rate

      # Process angel investment with 'accept'
      {:ok, %{game: updated_game}} = GameService.process_response(game.id, "accept")

      # Verify financial changes were processed correctly
      expected_cash =
        Decimal.sub(Decimal.add(initial_cash, Decimal.new("100000.00")), initial_burn)

      assert Decimal.compare(updated_game.cash_on_hand, expected_cash) == :eq
      assert Decimal.compare(updated_game.burn_rate, initial_burn) == :eq

      # Process hiring with 'experienced'
      {:ok, %{game: final_game}} = GameService.process_response(updated_game.id, "experienced")

      # Verify burn rate change
      expected_burn = Decimal.add(initial_burn, Decimal.new("3000.00"))
      assert Decimal.compare(final_game.burn_rate, expected_burn) == :eq
    end
  end

  describe "async recovery functions" do
    setup do
      user = AccountsFixtures.user_fixture()

      {:ok, %{game: game}} =
        GameService.create_and_start_game("Test Startup", "Testing", user, StaticScenarioProvider)

      %{user: user, game: game}
    end

    test "recover_missing_outcome_async starts streaming for incomplete round", %{game: game} do
      # Update the last round to have a response but no outcome
      round = List.last(game.rounds)

      {:ok, _} =
        Games.update_round(round, %{
          response: "accept",
          outcome: nil
        })

      # Call the function to start async recovery
      result = GameService.recover_missing_outcome_async(game.id, "accept")

      # Should return a stream ID
      assert {:ok, stream_id} = result
      assert is_binary(stream_id)
    end

    test "recover_next_scenario_async starts streaming for next scenario", %{game: game} do
      # Process a response to complete the first round
      {:ok, %{game: updated_game}} = GameService.process_response(game.id, "accept")

      # Call the function to start async recovery for next scenario
      result = GameService.recover_next_scenario_async(updated_game.id)

      # Should return a stream ID
      assert {:ok, stream_id} = result
      assert is_binary(stream_id)
    end

    test "handles error when async recovery fails" do
      # Test with non-existent game ID
      non_existent_id = Ecto.UUID.generate()

      # Call the recovery functions with invalid ID
      result1 = GameService.recover_missing_outcome_async(non_existent_id, "accept")
      result2 = GameService.recover_next_scenario_async(non_existent_id)

      # Both should return errors
      assert {:error, _} = result1
      assert {:error, _} = result2
    end
  end
end
