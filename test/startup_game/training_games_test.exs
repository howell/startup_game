defmodule StartupGame.TrainingGamesTest do
  # Use async if tests don't have ordering issues
  use StartupGame.DataCase, async: true

  alias StartupGame.TrainingGames
  alias StartupGame.Games

  import StartupGame.AccountsFixtures
  import StartupGame.GamesFixtures

  # Mock Provider using the MockStreamingAdapter
  defmodule MockTrainingProvider do
    use StartupGame.Engine.LLM.BaseScenarioProvider

    @impl true
    def llm_adapter, do: StartupGame.Mocks.LLM.MockStreamingAdapter

    @impl true
    def scenario_system_prompt, do: "Default Scenario Prompt"

    @impl true
    def outcome_system_prompt, do: "Default Outcome Prompt"

    def llm_options(), do: %{}
    def response_parser(), do: StartupGame.Engine.LLM.JSONResponseParser
    def create_scenario_prompt(_, _), do: "User Scenario Prompt"
    def create_outcome_prompt(_, _, _), do: "User Outcome Prompt"
    def should_end_game?(_), do: false
  end

  describe "regenerate_round_outcome_async/1" do
    setup do
      admin = admin_user_fixture()

      # Create a training game with one round using the MockTrainingProvider
      # Use game_fixture_with_rounds to ensure rounds exist synchronously
      training_game =
        game_fixture_with_rounds(
          1,
          %{
            name: "Regen Training Game",
            is_training_example: true,
            # Use mock provider
            provider_preference: Atom.to_string(MockTrainingProvider)
          },
          admin
        )

      # Ensure the game fixture created at least one round to test against
      # Reload to get associations potentially added by fixture helpers
      training_game = Games.get_game_with_associations!(training_game.id)
      # Get the first round
      round = hd(training_game.rounds)

      {:ok, training_game: training_game, round: round}
    end

    test "successfully starts regeneration stream for a valid round", %{round: round} do
      # Mocking GameService.load_game is complex due to state rebuilding.
      # We rely on the setup having created a valid state and test the TrainingGames call.
      # Check the structure and round ID separately due to preloading differences
      assert {:ok, stream_id, result_round} =
               TrainingGames.regenerate_round_outcome_async(round.id)

      assert is_binary(stream_id)
      assert result_round.id == round.id
    end

    test "returns error if game is not a training game", %{
      training_game: training_game,
      round: round
    } do
      # Update the game to NOT be a training example
      {:ok, _non_training_game} = Games.update_game(training_game, %{is_training_example: false})

      assert {:error, :not_a_training_game} =
               TrainingGames.regenerate_round_outcome_async(round.id)
    end

    test "returns error if round not found" do
      invalid_round_id = Ecto.UUID.generate()

      # Match the more specific error
      assert {:error, :round_not_found} =
               TrainingGames.regenerate_round_outcome_async(invalid_round_id)
    end

    test "uses custom outcome prompt if available", %{training_game: training_game, round: round} do
      custom_prompt = "This is a custom outcome prompt."

      # Prefix unused variable
      {:ok, _game_with_prompt} =
        Games.update_game(training_game, %{outcome_system_prompt: custom_prompt})

      # We need to verify the correct prompt is passed to the provider.
      # This requires more advanced mocking (e.g., using Mox) to intercept
      # the call to `generate_outcome_async`.
      # For now, we just ensure the call succeeds.
      assert {:ok, _stream_id, _round} = TrainingGames.regenerate_round_outcome_async(round.id)

      # TODO: Add Mox test to assert system_prompt argument passed to provider.generate_outcome_async
    end

    # TODO: Add test for LLM async call failure (requires mocking provider differently)
  end

  describe "finalize_regenerated_outcome/2" do
    setup do
      admin = admin_user_fixture()
      training_game = game_fixture_with_rounds(1, %{user_id: admin.id, is_training_example: true})
      round = round_fixture(training_game, %{outcome: "Original Outcome", cash_change: 100})
      {:ok, round: round}
    end

    test "updates the round with new outcome data including ownership changes", %{
      round: round
    } do
      new_outcome_data = %{
        "narrative" => "New Regenerated Outcome",
        "cash_change" => Decimal.new("-500.00"),
        "burn_rate_change" => Decimal.new("50.00"),
        # Simulate ownership changes from LLM (using string keys as LLM might return)
        "ownership_changes" => [
          %{
            "entity_name" => "Founder",
            "percentage" => Decimal.new("80.00"),
            "change_type" => "dilution",
            "previous_percentage" => Decimal.new("100.00")
          },
          %{
            "entity_name" => "New Investor",
            "percentage" => Decimal.new("20.00"),
            "change_type" => "investment",
            "previous_percentage" => Decimal.new("0.00")
          }
        ]
      }

      assert {:ok, updated_round} =
               TrainingGames.finalize_regenerated_outcome(round.id, new_outcome_data)

      assert updated_round.id == round.id
      assert updated_round.outcome == "New Regenerated Outcome"
      assert Decimal.equal?(updated_round.cash_change, Decimal.new("-500.00"))
      assert Decimal.equal?(updated_round.burn_rate_change, Decimal.new("50.00"))

      # Verify DB for round
      db_round = Games.get_round!(round.id)
      assert db_round.outcome == "New Regenerated Outcome"
      assert Decimal.equal?(db_round.cash_change, Decimal.new("-500.00"))

      # Verify DB for ownership changes associated with this round
      ownership_changes = Games.list_round_ownership_changes(updated_round.id)
      assert length(ownership_changes) == 2

      founder_change = Enum.find(ownership_changes, &(&1.entity_name == "Founder"))
      investor_change = Enum.find(ownership_changes, &(&1.entity_name == "New Investor"))

      assert founder_change
      assert Decimal.equal?(founder_change.previous_percentage, Decimal.new("100.00"))
      assert Decimal.equal?(founder_change.new_percentage, Decimal.new("80.00"))
      # Should be stored as atom
      assert founder_change.change_type == :dilution

      assert investor_change
      assert Decimal.equal?(investor_change.previous_percentage, Decimal.new("0.00"))
      assert Decimal.equal?(investor_change.new_percentage, Decimal.new("20.00"))
      # Should be stored as atom
      assert investor_change.change_type == :investment

      # Also verify the main Ownership records were updated (optional but good)
      game_ownerships = Games.list_game_ownerships(db_round.game_id)
      founder_ownership = Enum.find(game_ownerships, &(&1.entity_name == "Founder"))
      investor_ownership = Enum.find(game_ownerships, &(&1.entity_name == "New Investor"))

      assert founder_ownership
      assert Decimal.equal?(founder_ownership.percentage, Decimal.new("80.00"))
      assert investor_ownership
      assert Decimal.equal?(investor_ownership.percentage, Decimal.new("20.00"))
    end

    test "updates the round correctly when no ownership changes are provided", %{round: round} do
      new_outcome_data = %{
        narrative: "Simple Outcome Update",
        cash_change: Decimal.new("10.00"),
        burn_rate_change: Decimal.new("-5.00")
        # No ownership_changes key
      }

      assert {:ok, updated_round} =
               TrainingGames.finalize_regenerated_outcome(round.id, new_outcome_data)

      assert updated_round.outcome == "Simple Outcome Update"
      assert Decimal.equal?(updated_round.cash_change, Decimal.new("10.00"))

      # Verify no new ownership changes were created for this round
      ownership_changes = Games.list_round_ownership_changes(updated_round.id)
      assert Enum.empty?(ownership_changes)
    end

    test "returns error for invalid round id" do
      new_outcome_data = %{narrative: "Outcome", cash_change: 0, burn_rate_change: 0}
      invalid_round_id = Ecto.UUID.generate()

      assert_raise Ecto.NoResultsError, fn ->
        TrainingGames.finalize_regenerated_outcome(invalid_round_id, new_outcome_data)
      end
    end
  end
end
