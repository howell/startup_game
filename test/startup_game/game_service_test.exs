defmodule StartupGame.GameServiceTest do
  use StartupGame.DataCase

  import StartupGame.Test.Helpers.Streaming
  alias StartupGame.GameService
  alias StartupGame.Games
  alias StartupGame.Engine.Demo.StaticScenarioProvider
  alias StartupGame.AccountsFixtures
  alias StartupGame.Engine.GameState
  alias StartupGame.StreamingService

  # Helper function to process multiple inputs sequentially for state tests
  # Simulates the new flow: process input -> manually fetch next scenario -> manually create next round
  defp process_multiple_inputs(game_id, inputs) do
    Enum.reduce(inputs, {:ok, %{game_id: game_id}}, fn input,
                                                       {:ok, %{game_id: current_game_id}} ->
      # 1. Process the current input
      case GameService.process_player_input(current_game_id, input) do
        {:ok, %{game: game_after_input, game_state: gs_after_input}} ->
          # 2. Handle successful processing (fetch next scenario, create round if needed)
          handle_successful_input(game_after_input, gs_after_input)

        error ->
          # Stop processing on error
          error
      end
    end)
    |> case do
      # Return final game struct from DB (reloaded with all rounds)
      {:ok, %{game_id: final_game_id}} -> Games.get_game_with_associations!(final_game_id)
      # Return error tuple
      error -> error
    end
  end

  # Helper for process_multiple_inputs: handles logic after successful input processing
  defp handle_successful_input(game_after_input, gs_after_input) do
    if gs_after_input.status == :in_progress do
      # Fetch next scenario using the *updated* game state
      next_scenario =
        StaticScenarioProvider.get_next_scenario(
          gs_after_input,
          gs_after_input.current_scenario
        )

      # Create next round record in the DB if a scenario exists
      if next_scenario do
        {:ok, _round} =
          Games.create_round(%{
            situation: next_scenario.situation,
            game_id: game_after_input.id
          })
      end
    end

    # Always pass the game_id for the next iteration or final result
    {:ok, %{game_id: game_after_input.id}}
  end

  describe "create_game/6 and start_game/1" do
    setup do
      user = AccountsFixtures.user_fixture()
      %{user: user}
    end

    test "create_game creates a new game with database record", %{user: user} do
      # Test create_game directly
      {:ok, %{game: game, game_state: game_state}} =
        GameService.create_game("Test Startup", "Testing", user, StaticScenarioProvider)

      assert game.name == "Test Startup"
      assert game.description == "Testing"
      # Game state is created but not fully initialized with scenario yet
      assert game_state.name == "Test Startup"
      assert game_state.description == "Testing"
    end

    test "create_game initializes with correct default values", %{user: user} do
      {:ok, %{game: game, game_state: _game_state}} =
        GameService.create_game("Test Startup", "Testing", user, StaticScenarioProvider)

      assert Decimal.compare(game.cash_on_hand, Decimal.new("10000.00")) == :eq
      assert Decimal.compare(game.burn_rate, Decimal.new("1000.00")) == :eq
      # Default mode
      assert game.current_player_mode == :responding
      assert game.status == :in_progress
      # game_state status is default :in_progress, not asserted here as scenario isn't set yet
    end

    test "create_game respects initial_player_mode argument", %{user: user} do
      {:ok, %{game: game}} =
        GameService.create_game(
          "Acting Startup",
          "Testing acting mode",
          user,
          StaticScenarioProvider,
          %{},
          # Pass explicit mode
          :acting
        )

      assert game.current_player_mode == :acting
    end

    # Removed test "creates initial round with scenario" as create_game doesn't do this anymore.
    # start_game triggers async scenario request, harder to test synchronously here.

    test "create_game respects is_public and is_leaderboard_eligible preferences", %{user: user} do
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

    test "create_game respects user's default_game_visibility preference" do
      user = AccountsFixtures.user_fixture(%{default_game_visibility: :public})

      # Use create_game, not create_and_start_game
      {:ok, %{game: game}} =
        GameService.create_game("Test Startup", "Testing", user, StaticScenarioProvider)

      assert game.is_public == true
      assert game.is_leaderboard_eligible == true
    end
  end

  describe "load_game/1" do
    setup do
      user = AccountsFixtures.user_fixture()
      # Manually create game and first round for predictable state in load tests
      {:ok, %{game: game}} =
        GameService.create_game("Test Startup", "Testing", user, StaticScenarioProvider)

      # Manually create the first round record
      scenario = StaticScenarioProvider.get_next_scenario(%GameState{}, nil)
      # Fixed unused var warning
      {:ok, _round} = Games.create_round(%{situation: scenario.situation, game_id: game.id})
      # Reload game to include the created round for context in tests
      game = Games.get_game_with_associations!(game.id)

      %{user: user, game: game}
    end

    test "loads game from database", %{game: game} do
      {:ok, %{game: loaded_game, game_state: game_state}} =
        GameService.load_game(game.id)

      assert loaded_game.id == game.id
      assert game_state.name == "Test Startup"
      assert game_state.scenario_provider == StaticScenarioProvider
      # Check default mode loaded
      assert loaded_game.current_player_mode == :responding
    end

    test "builds game state with proper structure", %{game: game} do
      {:ok, %{game_state: game_state}} = GameService.load_game(game.id)

      assert game_state.cash_on_hand != nil
      assert game_state.burn_rate != nil
      assert game_state.status == :in_progress
      # Initial scenario should be loaded because create_and_start_game was used in setup
      assert game_state.current_scenario != nil
      assert game_state.current_scenario_data != nil
    end

    test "returns error for non-existent game" do
      non_existent_id = Ecto.UUID.generate()
      result = GameService.load_game(non_existent_id)

      assert result == {:error, "Game not found"}
    end

    test "loads rounds and current scenario correctly", %{game: game} do
      {:ok, %{game_state: game_state}} = GameService.load_game(game.id)
      assert game_state.current_scenario_data != nil
      assert game_state.current_scenario_data.situation =~ "An angel investor offers"

      # Process first input to complete the first round
      {:ok, %{game: game_after_first_input, game_state: gs_after_first_input}} =
        GameService.process_player_input(game.id, "accept")

      # Between rounds: game state does not have any current scenario data
      {:ok, %{game_state: game_state}} = GameService.load_game(game.id)
      assert game_state.current_scenario_data == nil
      assert game_state.current_scenario_data == nil

      # Manually create the second round record (simulating finalize_streamed_scenario)
      # Use the actual game state and completed scenario ID to get the next one
      next_scenario =
        StaticScenarioProvider.get_next_scenario(
          gs_after_first_input,
          gs_after_first_input.current_scenario
        )

      {:ok, _round2} =
        Games.create_round(%{
          situation: next_scenario.situation,
          game_id: game_after_first_input.id
        })

      # Now load the game
      {:ok, %{game: loaded_game_db, game_state: loaded_game_state}} =
        GameService.load_game(game_after_first_input.id)

      # DB game struct should have both rounds
      assert length(loaded_game_db.rounds) == 2
      [db_round1, db_round2] = Enum.sort_by(loaded_game_db.rounds, & &1.inserted_at)
      assert db_round1.situation =~ "An angel investor offers"
      assert db_round1.player_input == "accept"
      assert db_round1.outcome != nil
      assert db_round2.situation =~ "You need to hire a key employee"
      # Not yet processed
      assert db_round2.player_input == nil

      # In-memory game_state should only contain the *completed* first round in its history
      assert length(loaded_game_state.rounds) == 1
      [gs_round1] = loaded_game_state.rounds
      assert gs_round1.situation =~ "An angel investor offers"
      assert gs_round1.player_input == "accept"
      assert gs_round1.outcome != nil

      # The current scenario data should be the second round (hiring)
      assert loaded_game_state.current_scenario_data.id == "round_#{db_round2.id}"

      assert loaded_game_state.current_scenario_data.situation =~
               "You need to hire a key employee"
    end

    test "loads game ownerships correctly", %{game: game} do
      # Process an input that changes ownership
      {:ok, %{game: updated_game}} = GameService.process_player_input(game.id, "accept")

      # Now load the game and check ownerships in game_state
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

  describe "process_player_input/2" do
    setup do
      user = AccountsFixtures.user_fixture()

      # Create game but don't start it automatically
      {:ok, %{game: game}} =
        GameService.create_game("Test Startup", "Testing", user, StaticScenarioProvider)

      # Manually create the first round record for testing process_player_input
      scenario = StaticScenarioProvider.get_next_scenario(%GameState{}, nil)
      {:ok, round} = Games.create_round(%{situation: scenario.situation, game_id: game.id})
      # Associate round with game struct for setup context
      game = %{game | rounds: [round]}

      %{user: user, game: game}
    end

    test "processes input and updates round", %{game: game} do
      {:ok, %{game: updated_game}} =
        GameService.process_player_input(game.id, "accept")

      rounds = Games.list_game_rounds(updated_game.id)
      # Only one round exists, it gets updated
      assert length(rounds) == 1

      # Check the round was updated
      [first_round] = Enum.sort_by(rounds, & &1.inserted_at)
      # Use renamed field
      assert first_round.player_input == "accept"
      assert first_round.outcome != nil
      # Cannot assert next situation here as it's handled async/by caller
    end

    test "updates game state after input", %{game: game} do
      initial_cash = game.cash_on_hand

      {:ok, %{game: updated_game}} =
        GameService.process_player_input(game.id, "accept")

      # Game state should be updated (either cash or burn rate might change)
      # Note: Burn rate application happens in Engine, check final state
      assert updated_game.cash_on_hand != initial_cash ||
               updated_game.burn_rate != game.burn_rate
    end

    test "returns error for non-existent game" do
      non_existent_id = Ecto.UUID.generate()
      result = GameService.process_player_input(non_existent_id, "accept")

      assert result == {:error, "Game not found"}
    end

    test "processes input that changes cash_on_hand", %{game: game} do
      # Process sequence: accept -> experienced -> settle
      final_game = process_multiple_inputs(game.id, ["accept", "experienced", "settle"])

      # Verify cash change is applied correctly over sequence
      # Initial: 10000
      # After accept: +100000 - 1000 = 109000
      # After experienced: - (1000 + 3000) = 105000
      # After settle: -50000 - (1000 + 3000) = 51000
      assert Decimal.compare(final_game.cash_on_hand, Decimal.new("51000.00")) == :eq
    end

    test "processes input that changes burn_rate", %{game: game} do
      # Process sequence: accept -> experienced
      final_game = process_multiple_inputs(game.id, ["accept", "experienced"])

      # Verify burn rate change is +3000.00
      expected_burn_rate = Decimal.add(Decimal.new("1000.00"), Decimal.new("3000.00"))
      assert Decimal.compare(final_game.burn_rate, expected_burn_rate) == :eq
    end

    test "processes input that changes ownership structure", %{game: game} do
      # Process 'accept' response to angel investment scenario
      {:ok, %{game: updated_game}} = GameService.process_player_input(game.id, "accept")

      # Verify ownership changes were processed correctly
      updated_ownerships = Games.list_game_ownerships(updated_game.id)
      assert length(updated_ownerships) == 2

      founder = Enum.find(updated_ownerships, &(&1.entity_name == "Founder"))
      investor = Enum.find(updated_ownerships, &(&1.entity_name == "Angel Investor"))

      assert founder != nil
      assert investor != nil
      assert Decimal.compare(founder.percentage, Decimal.new("85.00")) == :eq
      assert Decimal.compare(investor.percentage, Decimal.new("15.00")) == :eq
    end

    test "processes input that triggers game exit", %{game: game} do
      # Process sequence: accept -> experienced -> settle -> accept
      final_game = process_multiple_inputs(game.id, ["accept", "experienced", "settle", "accept"])

      # Verify game status and exit details
      assert final_game.status == :completed
      assert final_game.exit_type == :acquisition
      assert Decimal.compare(final_game.exit_value, Decimal.new("2000000.00")) == :eq
    end

    # This test might need rethinking as process_player_input expects a round to update
    @tag :skip
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
      result = GameService.process_player_input(empty_game.id, "accept")

      # Should fail gracefully, not crash
      assert {:error, _} = result
    end

    test "processes invalid inputs gracefully", %{game: game} do
      # Send a completely invalid response
      result = GameService.process_player_input(game.id, "xxxxxxxxx")

      # Should return error but not crash
      assert {:error, message} = result

      assert message =~ "Please try again"
    end

    test "completes financial transaction properly", %{game: game} do
      # Capture initial financial state
      initial_cash = game.cash_on_hand
      initial_burn = game.burn_rate

      # Process angel investment with 'accept'
      {:ok, %{game: updated_game}} = GameService.process_player_input(game.id, "accept")

      # Verify financial changes were processed correctly
      expected_cash =
        Decimal.sub(Decimal.add(initial_cash, Decimal.new("100000.00")), initial_burn)

      assert Decimal.compare(updated_game.cash_on_hand, expected_cash) == :eq
      # Burn rate unchanged after 'accept'
      assert Decimal.compare(updated_game.burn_rate, initial_burn) == :eq

      :ok = StreamingService.subscribe(updated_game.id)
      {:ok, _} = GameService.request_next_scenario_async(updated_game.id)

      assert_stream_complete({:ok, next_scenario})
      assert next_scenario.situation =~ "You need to hire a key employee"
      {:ok, _} = GameService.finalize_streamed_scenario(updated_game.id, next_scenario)

      # Process hiring with 'experienced' (using the same game ID, which now has the new 'hiring' round waiting)
      # Rename to avoid confusion
      {:ok, %{game: returned_final_game}} =
        GameService.process_player_input(updated_game.id, "experienced")

      # Explicitly reload from DB to ensure persistence
      reloaded_final_game = Games.get_game!(updated_game.id)

      # Verify burn rate change
      expected_burn = Decimal.add(initial_burn, Decimal.new("3000.00"))

      # Assert against the reloaded game
      assert Decimal.compare(reloaded_final_game.burn_rate, expected_burn) == :eq,
             "Burn rate in DB was not updated correctly"

      # Also check the returned game struct just in case
      assert Decimal.compare(returned_final_game.burn_rate, expected_burn) == :eq,
             "Returned game struct did not have updated burn rate"
    end
  end

  # describe "start_next_round/2" removed as function was removed

  describe "sequence steps from static provider correctly" do
    setup do
      user = AccountsFixtures.user_fixture()
      # Use create_game and manually create first round
      {:ok, %{game: game}} =
        GameService.create_game("Test Startup", "Testing", user, StaticScenarioProvider)

      scenario = StaticScenarioProvider.get_next_scenario(%GameState{}, nil)
      {:ok, round} = Games.create_round(%{situation: scenario.situation, game_id: game.id})
      game = %{game | rounds: [round]}
      %{user: user, game: game}
    end

    test "processes inputs in sequence", %{game: game} do
      # Use helper to process sequence
      final_game = process_multiple_inputs(game.id, ["accept", "experienced", "s"])

      rounds = Games.list_game_rounds(final_game.id)
      # 3 inputs processed + 1 new round created
      assert length(rounds) == 4

      # Check all rounds in order
      sorted_rounds = Enum.sort_by(rounds, & &1.inserted_at)
      [first, second, third, fourth] = sorted_rounds

      assert first.situation =~ "An angel investor offers"
      # Use renamed field
      assert first.player_input == "accept"
      assert first.outcome =~ "You accept the offer and receive the investment"

      assert second.situation =~ "You need to hire a key employee"
      # Use renamed field
      assert second.player_input == "experienced"
      assert second.outcome =~ "The experienced developer brings immediate value"

      assert third.situation =~ "Your startup has been sued"
      # Use renamed field
      assert third.player_input == "s"
      assert third.outcome =~ "You settle the lawsuit for $50,000"

      # The fourth round only exists after processing the third input
      # and requesting the next scenario
      assert fourth.situation =~ "A larger company offers to acquire your startup"
      # No input yet for the last round
      assert fourth.player_input == nil
    end

    test "processes full game lifecycle through acquisition exit", %{game: game} do
      # Process all four scenarios with responses that lead to acquisition
      final_game = process_multiple_inputs(game.id, ["accept", "experienced", "settle", "accept"])

      # Verify final game state
      assert final_game.status == :completed
      assert final_game.exit_type == :acquisition
      assert Decimal.compare(final_game.exit_value, Decimal.new("2000000.00")) == :eq

      # Check that all rounds were created and have proper responses/outcomes
      rounds = Games.list_game_rounds(final_game.id)
      assert length(rounds) == 4

      # All rounds should have player_inputs and outcomes
      for round <- Enum.sort_by(rounds, & &1.inserted_at) do
        assert round.player_input != nil
        assert round.outcome != nil
      end
    end
  end

  describe "save_round_result (through process_player_input)" do
    setup do
      user = AccountsFixtures.user_fixture()
      # Use create_game and manually create first round
      {:ok, %{game: game}} =
        GameService.create_game("Test Startup", "Testing", user, StaticScenarioProvider)

      scenario = StaticScenarioProvider.get_next_scenario(%GameState{}, nil)
      {:ok, round} = Games.create_round(%{situation: scenario.situation, game_id: game.id})
      game = %{game | rounds: [round]}
      %{user: user, game: game}
    end

    test "saves player_input and outcome to the round", %{game: game} do
      # First process an input
      {:ok, %{game: updated_game, game_state: game_state}} =
        GameService.process_player_input(game.id, "accept")

      # Verify the round was updated correctly
      rounds = Games.list_game_rounds(updated_game.id)
      sorted_rounds = Enum.sort_by(rounds, & &1.inserted_at)
      # Only one round exists initially
      [first_round] = sorted_rounds

      # Use renamed field
      assert first_round.player_input == "accept"
      assert first_round.outcome =~ "You accept the offer and receive the investment"
      assert Decimal.compare(first_round.cash_change, Decimal.new("100000.00")) == :eq
      assert Decimal.compare(first_round.burn_rate_change, Decimal.new("0.00")) == :eq

      # Keeps the game state in sync
      assert [gs_first_round] = game_state.rounds
      assert gs_first_round.situation =~ "An angel investor offers"
      assert gs_first_round.player_input == "accept"
      assert gs_first_round.outcome =~ "You accept the offer and receive the investment"
      assert Decimal.compare(gs_first_round.cash_change, Decimal.new("100000.00")) == :eq
      assert Decimal.compare(gs_first_round.burn_rate_change, Decimal.new("0.00")) == :eq
      assert game_state.current_scenario == "round_#{first_round.id}"
      assert game_state.current_scenario_data.situation =~ "An angel investor offers"
    end

    test "handles ownership changes correctly", %{game: game} do
      # Initial ownership should be 100% founder
      initial_ownerships = Games.list_game_ownerships(game.id)
      assert length(initial_ownerships) == 1
      [founder] = initial_ownerships
      assert founder.entity_name == "Founder"
      assert Decimal.compare(founder.percentage, Decimal.new("100.00")) == :eq

      # Process angel investment with 'accept' response
      {:ok, %{game: updated_game}} = GameService.process_player_input(game.id, "accept")

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
      final_game = process_multiple_inputs(game.id, ["accept", "experienced"])

      # Get ownership before lawsuit
      ownerships_before = Games.list_game_ownerships(final_game.id)

      # Respond to lawsuit with 'settle'
      {:ok, %{game: final_game_after_settle}} =
        GameService.process_player_input(final_game.id, "settle")

      # Verify ownerships are unchanged
      ownerships_after = Games.list_game_ownerships(final_game_after_settle.id)
      assert length(ownerships_before) == length(ownerships_after)

      # Verify no ownership changes were recorded
      rounds = Games.list_game_rounds(final_game_after_settle.id)
      # Use renamed field
      lawsuit_round = Enum.find(rounds, &(&1.player_input == "settle"))
      ownership_changes = Games.list_round_ownership_changes(lawsuit_round.id)
      assert ownership_changes == []
    end

    test "updates game status and exit information correctly", %{game: game} do
      # Process all scenarios to reach acquisition
      final_game = process_multiple_inputs(game.id, ["accept", "experienced", "settle"])

      # Verify game is still in progress
      assert final_game.status == :in_progress
      assert final_game.exit_type == :none

      # Process acquisition with 'accept'
      {:ok, %{game: final_game_after_exit}} =
        GameService.process_player_input(final_game.id, "accept")

      # Verify game status and exit info were updated
      assert final_game_after_exit.status == :completed
      assert final_game_after_exit.exit_type == :acquisition
      assert Decimal.compare(final_game_after_exit.exit_value, Decimal.new("2000000.00")) == :eq
    end
  end

  describe "async recovery functions" do
    setup do
      user = AccountsFixtures.user_fixture()
      # Use create_game and manually create first round
      {:ok, %{game: game}} =
        GameService.create_game("Test Startup", "Testing", user, StaticScenarioProvider)

      scenario = StaticScenarioProvider.get_next_scenario(%GameState{}, nil)
      {:ok, round} = Games.create_round(%{situation: scenario.situation, game_id: game.id})
      game = %{game | rounds: [round]}
      %{user: user, game: game}
    end

    test "recover_missing_outcome_async starts streaming for incomplete round", %{game: game} do
      # Update the last round to have player_input but no outcome
      round = List.last(game.rounds)

      {:ok, _} =
        Games.update_round(round, %{
          # Use renamed field
          player_input: "accept",
          outcome: nil
        })

      # Call the function to start async recovery
      result = GameService.recover_missing_outcome_async(game.id, "accept")

      # Should return a stream ID
      assert {:ok, stream_id} = result
      assert is_binary(stream_id)
    end

    # test "recover_next_scenario_async starts streaming for next scenario" removed as function was removed

    test "handles error when async recovery fails" do
      # Test with non-existent game ID
      non_existent_id = Ecto.UUID.generate()

      # Call the recovery functions with invalid ID
      result1 = GameService.recover_missing_outcome_async(non_existent_id, "accept")
      # result2 = GameService.recover_next_scenario_async(non_existent_id) # Function removed

      # Both should return errors
      assert {:error, _} = result1
      # assert {:error, _} = result2 # Test removed
    end
  end
end
