defmodule StartupGame.GamesTest do
  use StartupGame.DataCase

  alias StartupGame.Accounts
  alias StartupGame.Games
  alias StartupGame.Games.Game
  alias StartupGame.Games.Round
  alias StartupGame.Games.Ownership
  alias StartupGame.Games.OwnershipChange

  import StartupGame.AccountsFixtures
  import StartupGame.GamesFixtures, only: [game_fixture_with_ownership: 2]

  # Fixtures for testing

  def game_fixture(attrs \\ %{}) do
    user = user_fixture()

    {:ok, game} =
      attrs
      |> Enum.into(%{
        name: "Test Startup",
        description: "A test startup for unit tests",
        cash_on_hand: Decimal.new("10000.00"),
        burn_rate: Decimal.new("1000.00"),
        status: :in_progress,
        is_public: false,
        is_leaderboard_eligible: false,
        exit_value: Decimal.new("0.00"),
        exit_type: :none,
        user_id: user.id
      })
      |> Games.create_game()

    game
  end

  def round_fixture(attrs \\ %{}) do
    game = attrs[:game] || game_fixture()

    {:ok, round} =
      attrs
      |> Enum.into(%{
        situation: "Test situation",
        response: "Test response",
        outcome: "Test outcome",
        cash_change: Decimal.new("1000.00"),
        burn_rate_change: Decimal.new("100.00"),
        game_id: game.id
      })
      |> Games.create_round()

    # Return the round with game association
    %{round | game: game}
  end

  def ownership_fixture(attrs \\ %{}) do
    game = attrs[:game] || game_fixture()

    {:ok, ownership} =
      attrs
      |> Enum.into(%{
        entity_name: "Test Entity",
        percentage: Decimal.new("50.00"),
        game_id: game.id
      })
      |> Games.create_ownership()

    ownership
  end

  def ownership_change_fixture(attrs \\ %{}) do
    game = attrs[:game] || game_fixture()
    round = attrs[:round] || round_fixture(%{game: game})

    {:ok, ownership_change} =
      attrs
      |> Enum.into(%{
        entity_name: "Test Entity",
        previous_percentage: Decimal.new("0.00"),
        new_percentage: Decimal.new("50.00"),
        change_type: :initial,
        game_id: game.id,
        round_id: round.id
      })
      |> Games.create_ownership_change()

    ownership_change
  end

  # Game tests

  describe "games" do
    test "list_games/0 returns all games" do
      game = game_fixture()
      assert Games.list_games() |> Enum.map(& &1.id) |> Enum.member?(game.id)
    end

    test "list_user_games/1 returns games for a specific user" do
      game = game_fixture()
      assert Games.list_user_games(game.user_id) |> Enum.map(& &1.id) |> Enum.member?(game.id)
      assert Games.list_user_games(Ecto.UUID.generate()) == []
    end

    test "list_leaderboard_games/0 returns eligible games" do
      # Create a non-eligible game
      game_fixture()

      # Create an eligible game
      user = user_fixture()

      {:ok, eligible_game} =
        %{
          name: "Eligible Game",
          description: "A game eligible for leaderboard",
          cash_on_hand: Decimal.new("10000.00"),
          burn_rate: Decimal.new("1000.00"),
          status: :completed,
          is_public: true,
          is_leaderboard_eligible: true,
          exit_value: Decimal.new("1000000.00"),
          exit_type: :acquisition,
          user_id: user.id
        }
        |> Games.create_game()

      leaderboard_games = Games.list_leaderboard_games()
      assert Enum.any?(leaderboard_games, fn g -> g.id == eligible_game.id end)
    end

    test "get_game!/1 returns the game with given id" do
      game = game_fixture()
      assert Games.get_game!(game.id).id == game.id
    end

    test "get_game_with_associations!/1 returns the game with associations" do
      game = game_fixture()
      round_fixture(%{game: game})
      ownership_fixture(%{game: game})

      game_with_assocs = Games.get_game_with_associations!(game.id)
      assert game_with_assocs.id == game.id
      assert length(game_with_assocs.rounds) == 1
      assert length(game_with_assocs.ownerships) == 1
    end

    test "create_game/1 with valid data creates a game" do
      user = user_fixture()

      valid_attrs = %{
        name: "New Startup",
        description: "A new startup description",
        cash_on_hand: Decimal.new("20000.00"),
        burn_rate: Decimal.new("2000.00"),
        user_id: user.id
      }

      assert {:ok, %Game{} = game} = Games.create_game(valid_attrs)
      assert game.name == "New Startup"
      assert game.description == "A new startup description"
      assert Decimal.equal?(game.cash_on_hand, Decimal.new("20000.00"))
      assert Decimal.equal?(game.burn_rate, Decimal.new("2000.00"))
    end

    test "create_game/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Games.create_game(%{})
    end

    test "create_new_game/2 creates a game with initial ownership" do
      user = user_fixture()

      valid_attrs = %{
        name: "New Startup",
        description: "A new startup description"
      }

      assert {:ok, %Game{} = game} = Games.create_new_game(valid_attrs, user)
      assert game.name == "New Startup"
      assert game.description == "A new startup description"

      # Check that initial ownership was created
      ownerships = Games.list_game_ownerships(game.id)
      assert length(ownerships) == 1
      assert hd(ownerships).entity_name == "Founder"
      assert Decimal.equal?(hd(ownerships).percentage, Decimal.new("100.00"))
    end

    test "update_game/2 with valid data updates the game" do
      game = game_fixture()

      update_attrs = %{
        name: "Updated Name",
        description: "Updated description",
        cash_on_hand: Decimal.new("30000.00")
      }

      assert {:ok, %Game{} = updated_game} = Games.update_game(game, update_attrs)
      assert updated_game.name == "Updated Name"
      assert updated_game.description == "Updated description"
      assert Decimal.equal?(updated_game.cash_on_hand, Decimal.new("30000.00"))
    end

    test "update_game/2 with invalid data returns error changeset" do
      game = game_fixture()
      assert {:error, %Ecto.Changeset{}} = Games.update_game(game, %{name: nil})
      assert game.id == Games.get_game!(game.id).id
    end

    test "delete_game/1 deletes the game" do
      game = game_fixture()
      assert {:ok, %Game{}} = Games.delete_game(game)
      assert_raise Ecto.NoResultsError, fn -> Games.get_game!(game.id) end
    end

    test "change_game/1 returns a game changeset" do
      game = game_fixture()
      assert %Ecto.Changeset{} = Games.change_game(game)
    end
  end

  # Round tests

  describe "rounds" do
    test "list_game_rounds/1 returns all rounds for a game" do
      game = game_fixture()
      round = round_fixture(%{game: game})
      assert Games.list_game_rounds(game.id) |> Enum.map(& &1.id) |> Enum.member?(round.id)
    end

    test "get_round!/1 returns the round with given id" do
      round = round_fixture()
      assert Games.get_round!(round.id).id == round.id
    end

    test "create_round/1 with valid data creates a round" do
      game = game_fixture()

      valid_attrs = %{
        situation: "New situation",
        response: "New response",
        outcome: "New outcome",
        cash_change: Decimal.new("2000.00"),
        burn_rate_change: Decimal.new("200.00"),
        game_id: game.id
      }

      assert {:ok, %Round{} = round} = Games.create_round(valid_attrs)
      assert round.situation == "New situation"
      assert round.response == "New response"
      assert round.outcome == "New outcome"
      assert Decimal.equal?(round.cash_change, Decimal.new("2000.00"))
      assert Decimal.equal?(round.burn_rate_change, Decimal.new("200.00"))
    end

    test "create_round/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Games.create_round(%{})
    end

    test "create_game_round/2 creates a round and updates game state" do
      game = game_fixture()
      initial_cash = game.cash_on_hand
      initial_burn_rate = game.burn_rate

      round_attrs = %{
        situation: "Test situation",
        cash_change: Decimal.new("5000.00"),
        burn_rate_change: Decimal.new("500.00")
      }

      assert {:ok, %{round: round, game: updated_game}} =
               Games.create_game_round(round_attrs, game)

      assert round.situation == "Test situation"

      # Check that game state was updated
      expected_cash = Decimal.add(initial_cash, Decimal.new("5000.00"))
      expected_burn_rate = Decimal.add(initial_burn_rate, Decimal.new("500.00"))

      assert Decimal.equal?(updated_game.cash_on_hand, expected_cash)
      assert Decimal.equal?(updated_game.burn_rate, expected_burn_rate)
    end

    test "update_round/2 with valid data updates the round" do
      round = round_fixture()

      update_attrs = %{
        situation: "Updated situation",
        response: "Updated response"
      }

      assert {:ok, %Round{} = updated_round} = Games.update_round(round, update_attrs)
      assert updated_round.situation == "Updated situation"
      assert updated_round.response == "Updated response"
    end

    test "update_round/2 with invalid data returns error changeset" do
      round = round_fixture()
      assert {:error, %Ecto.Changeset{}} = Games.update_round(round, %{situation: nil})
      assert round.id == Games.get_round!(round.id).id
    end

    test "delete_round/1 deletes the round" do
      round = round_fixture()
      assert {:ok, %Round{}} = Games.delete_round(round)
      assert_raise Ecto.NoResultsError, fn -> Games.get_round!(round.id) end
    end

    test "change_round/1 returns a round changeset" do
      round = round_fixture()
      assert %Ecto.Changeset{} = Games.change_round(round)
    end
  end

  # Ownership tests

  describe "ownerships" do
    test "list_game_ownerships/1 returns all ownerships for a game" do
      game = game_fixture()
      ownership = ownership_fixture(%{game: game})

      assert Games.list_game_ownerships(game.id)
             |> Enum.map(& &1.id)
             |> Enum.member?(ownership.id)
    end

    test "get_ownership!/1 returns the ownership with given id" do
      ownership = ownership_fixture()
      assert Games.get_ownership!(ownership.id).id == ownership.id
    end

    test "create_ownership/1 with valid data creates an ownership" do
      game = game_fixture()

      valid_attrs = %{
        entity_name: "New Entity",
        percentage: Decimal.new("25.00"),
        game_id: game.id
      }

      assert {:ok, %Ownership{} = ownership} = Games.create_ownership(valid_attrs)
      assert ownership.entity_name == "New Entity"
      assert Decimal.equal?(ownership.percentage, Decimal.new("25.00"))
    end

    test "create_ownership/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Games.create_ownership(%{})
    end

    test "update_ownership/2 with valid data updates the ownership" do
      ownership = ownership_fixture()

      update_attrs = %{
        entity_name: "Updated Entity",
        percentage: Decimal.new("75.00")
      }

      assert {:ok, %Ownership{} = updated_ownership} =
               Games.update_ownership(ownership, update_attrs)

      assert updated_ownership.entity_name == "Updated Entity"
      assert Decimal.equal?(updated_ownership.percentage, Decimal.new("75.00"))
    end

    test "update_ownership/2 with invalid data returns error changeset" do
      ownership = ownership_fixture()
      assert {:error, %Ecto.Changeset{}} = Games.update_ownership(ownership, %{entity_name: nil})
      assert ownership.id == Games.get_ownership!(ownership.id).id
    end

    test "delete_ownership/1 deletes the ownership" do
      ownership = ownership_fixture()
      assert {:ok, %Ownership{}} = Games.delete_ownership(ownership)
      assert_raise Ecto.NoResultsError, fn -> Games.get_ownership!(ownership.id) end
    end

    test "change_ownership/1 returns an ownership changeset" do
      ownership = ownership_fixture()
      assert %Ecto.Changeset{} = Games.change_ownership(ownership)
    end
  end

  # OwnershipChange tests

  describe "ownership_changes" do
    test "list_game_ownership_changes/1 returns all ownership changes for a game" do
      game = game_fixture()
      ownership_change = ownership_change_fixture(%{game: game})

      assert Games.list_game_ownership_changes(game.id)
             |> Enum.map(& &1.id)
             |> Enum.member?(ownership_change.id)
    end

    test "list_round_ownership_changes/1 returns all ownership changes for a round" do
      round = round_fixture()
      ownership_change = ownership_change_fixture(%{round: round, game: round.game})

      assert Games.list_round_ownership_changes(round.id)
             |> Enum.map(& &1.id)
             |> Enum.member?(ownership_change.id)
    end

    test "get_ownership_change!/1 returns the ownership change with given id" do
      ownership_change = ownership_change_fixture()
      assert Games.get_ownership_change!(ownership_change.id).id == ownership_change.id
    end

    test "create_ownership_change/1 with valid data creates an ownership change" do
      game = game_fixture()
      round = round_fixture(%{game: game})

      valid_attrs = %{
        entity_name: "New Entity",
        previous_percentage: Decimal.new("0.00"),
        new_percentage: Decimal.new("25.00"),
        change_type: :initial,
        game_id: game.id,
        round_id: round.id
      }

      assert {:ok, %OwnershipChange{} = ownership_change} =
               Games.create_ownership_change(valid_attrs)

      assert ownership_change.entity_name == "New Entity"
      assert Decimal.equal?(ownership_change.previous_percentage, Decimal.new("0.00"))
      assert Decimal.equal?(ownership_change.new_percentage, Decimal.new("25.00"))
      assert ownership_change.change_type == :initial
    end

    test "create_ownership_change/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Games.create_ownership_change(%{})
    end

    test "update_ownership_change/2 with valid data updates the ownership change" do
      ownership_change = ownership_change_fixture()

      update_attrs = %{
        entity_name: "Updated Entity",
        new_percentage: Decimal.new("75.00")
      }

      assert {:ok, %OwnershipChange{} = updated_change} =
               Games.update_ownership_change(ownership_change, update_attrs)

      assert updated_change.entity_name == "Updated Entity"
      assert Decimal.equal?(updated_change.new_percentage, Decimal.new("75.00"))
    end

    test "update_ownership_change/2 with invalid data returns error changeset" do
      ownership_change = ownership_change_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Games.update_ownership_change(ownership_change, %{entity_name: nil})

      assert ownership_change.id == Games.get_ownership_change!(ownership_change.id).id
    end

    test "delete_ownership_change/1 deletes the ownership change" do
      ownership_change = ownership_change_fixture()
      assert {:ok, %OwnershipChange{}} = Games.delete_ownership_change(ownership_change)
      assert_raise Ecto.NoResultsError, fn -> Games.get_ownership_change!(ownership_change.id) end
    end

    test "change_ownership_change/1 returns an ownership change changeset" do
      ownership_change = ownership_change_fixture()
      assert %Ecto.Changeset{} = Games.change_ownership_change(ownership_change)
    end
  end

  # Game state tests

  describe "game state" do
    test "calculate_runway/1 calculates the runway correctly" do
      game =
        game_fixture(%{cash_on_hand: Decimal.new("10000.00"), burn_rate: Decimal.new("2000.00")})

      runway = Games.calculate_runway(game)
      assert Decimal.equal?(runway, Decimal.new("5"))
    end

    test "calculate_runway/1 handles zero burn rate" do
      game =
        game_fixture(%{cash_on_hand: Decimal.new("10000.00"), burn_rate: Decimal.new("0.00")})

      runway = Games.calculate_runway(game)
      assert Decimal.equal?(runway, Decimal.new("999"))
    end

    test "complete_game/3 completes a game with acquisition" do
      game = game_fixture()

      assert {:ok, updated_game} =
               Games.complete_game(game, :acquisition, Decimal.new("1000000.00"))

      assert updated_game.status == :completed
      assert updated_game.exit_type == :acquisition
      assert Decimal.equal?(updated_game.exit_value, Decimal.new("1000000.00"))
    end

    test "complete_game/3 completes a game with IPO" do
      game = game_fixture()
      assert {:ok, updated_game} = Games.complete_game(game, :ipo, Decimal.new("5000000.00"))
      assert updated_game.status == :completed
      assert updated_game.exit_type == :ipo
      assert Decimal.equal?(updated_game.exit_value, Decimal.new("5000000.00"))
    end

    test "fail_game/2 fails a game" do
      game = game_fixture()
      assert {:ok, updated_game} = Games.fail_game(game)
      assert updated_game.status == :failed
      assert updated_game.exit_type == :shutdown
    end
  end

  # Leaderboard tests

  describe "leaderboard data" do
    test "list_leaderboard_data/1 returns formatted leaderboard entries" do
      # Create user and completed game with known exit value and ownership
      user = user_fixture(%{email: "test@example.com"})

      game =
        game_fixture(%{
          name: "Test Company",
          exit_type: :acquisition,
          exit_value: Decimal.new("2000000"),
          is_public: true,
          is_leaderboard_eligible: true,
          status: :completed,
          user_id: user.id
        })

      # Create a round for the game (needed for ownership changes)
      _round = round_fixture(%{game: game})

      # Create founder ownership with 60% equity
      ownership_fixture(%{
        game: game,
        entity_name: "Founder",
        percentage: Decimal.new("60.0")
      })

      # Get leaderboard data
      [entry] = Games.list_leaderboard_data()

      # Verify the entry has the expected fields and values
      assert entry.username == "test"
      assert entry.company_name == "Test Company"
      assert Decimal.equal?(entry.exit_value, Decimal.new("2000000"))
      # 60% of exit value
      assert Decimal.equal?(entry.yield, Decimal.new("1200000"))
      assert entry.user_id == user.id
    end

    test "list_leaderboard_data/1 sorts by exit_value desc by default" do
      # Create multiple games with different exit values
      user1 = user_fixture(%{email: "user1@example.com"})
      user2 = user_fixture(%{email: "user2@example.com"})
      user3 = user_fixture(%{email: "user3@example.com"})

      # Game A - highest exit value
      game_a =
        game_fixture(%{
          name: "Company A",
          exit_type: :acquisition,
          exit_value: Decimal.new("3000000"),
          is_public: true,
          is_leaderboard_eligible: true,
          status: :completed,
          user_id: user1.id
        })

      _round_a = round_fixture(%{game: game_a})
      ownership_fixture(%{game: game_a, entity_name: "Founder", percentage: Decimal.new("50.0")})

      # Game B - lowest exit value
      game_b =
        game_fixture(%{
          name: "Company B",
          exit_type: :acquisition,
          exit_value: Decimal.new("1000000"),
          is_public: true,
          is_leaderboard_eligible: true,
          status: :completed,
          user_id: user2.id
        })

      _round_b = round_fixture(%{game: game_b})
      ownership_fixture(%{game: game_b, entity_name: "Founder", percentage: Decimal.new("50.0")})

      # Game C - middle exit value
      game_c =
        game_fixture(%{
          name: "Company C",
          exit_type: :acquisition,
          exit_value: Decimal.new("2000000"),
          is_public: true,
          is_leaderboard_eligible: true,
          status: :completed,
          user_id: user3.id
        })

      _round_c = round_fixture(%{game: game_c})
      ownership_fixture(%{game: game_c, entity_name: "Founder", percentage: Decimal.new("50.0")})

      # Get leaderboard data (default sort is exit_value desc)
      entries = Games.list_leaderboard_data()

      # Verify order: A, C, B (descending exit value)
      assert length(entries) == 3
      assert Enum.map(entries, & &1.company_name) == ["Company A", "Company C", "Company B"]
    end

    test "list_leaderboard_data/1 can sort by exit_value asc" do
      # Create multiple games with different exit values (reusing setup from previous test)
      user1 = user_fixture(%{email: "user1@example.com"})
      user2 = user_fixture(%{email: "user2@example.com"})
      user3 = user_fixture(%{email: "user3@example.com"})

      # Game A - highest exit value
      game_a =
        game_fixture(%{
          name: "Company A",
          exit_type: :acquisition,
          exit_value: Decimal.new("3000000"),
          is_public: true,
          is_leaderboard_eligible: true,
          status: :completed,
          user_id: user1.id
        })

      _round_a = round_fixture(%{game: game_a})
      ownership_fixture(%{game: game_a, entity_name: "Founder", percentage: Decimal.new("50.0")})

      # Game B - lowest exit value
      game_b =
        game_fixture(%{
          name: "Company B",
          exit_type: :acquisition,
          exit_value: Decimal.new("1000000"),
          is_public: true,
          is_leaderboard_eligible: true,
          status: :completed,
          user_id: user2.id
        })

      _round_b = round_fixture(%{game: game_b})
      ownership_fixture(%{game: game_b, entity_name: "Founder", percentage: Decimal.new("50.0")})

      # Game C - middle exit value
      game_c =
        game_fixture(%{
          name: "Company C",
          exit_type: :acquisition,
          exit_value: Decimal.new("2000000"),
          is_public: true,
          is_leaderboard_eligible: true,
          status: :completed,
          user_id: user3.id
        })

      _round_c = round_fixture(%{game: game_c})
      ownership_fixture(%{game: game_c, entity_name: "Founder", percentage: Decimal.new("50.0")})

      # Get leaderboard data with ascending sort
      entries = Games.list_leaderboard_data(%{sort_by: "exit_value", sort_direction: :asc})

      # Verify order: B, C, A (ascending exit value)
      assert length(entries) == 3
      assert Enum.map(entries, & &1.company_name) == ["Company B", "Company C", "Company A"]
    end

    test "list_leaderboard_data/1 can sort by yield" do
      # Create multiple games with different founder percentages and exit values
      user1 = user_fixture(%{email: "user1@example.com"})
      user2 = user_fixture(%{email: "user2@example.com"})
      user3 = user_fixture(%{email: "user3@example.com"})

      # Game A: $3M exit, 40% founder ownership = $1.2M yield
      game_a =
        game_fixture(%{
          name: "Company A",
          exit_type: :acquisition,
          exit_value: Decimal.new("3000000"),
          is_public: true,
          is_leaderboard_eligible: true,
          status: :completed,
          user_id: user1.id,
          # Explicitly set founder_return
          founder_return: Decimal.new("1200000")
        })

      _round_a = round_fixture(%{game: game_a})
      ownership_fixture(%{game: game_a, entity_name: "Founder", percentage: Decimal.new("40.0")})

      # Game B: $1M exit, 90% founder ownership = $0.9M yield
      game_b =
        game_fixture(%{
          name: "Company B",
          exit_type: :acquisition,
          exit_value: Decimal.new("1000000"),
          is_public: true,
          is_leaderboard_eligible: true,
          status: :completed,
          user_id: user2.id,
          # Explicitly set founder_return
          founder_return: Decimal.new("900000")
        })

      _round_b = round_fixture(%{game: game_b})
      ownership_fixture(%{game: game_b, entity_name: "Founder", percentage: Decimal.new("90.0")})

      # Game C: $2M exit, 80% founder ownership = $1.6M yield
      game_c =
        game_fixture(%{
          name: "Company C",
          exit_type: :acquisition,
          exit_value: Decimal.new("2000000"),
          is_public: true,
          is_leaderboard_eligible: true,
          status: :completed,
          user_id: user3.id,
          # Explicitly set founder_return
          founder_return: Decimal.new("1600000")
        })

      _round_c = round_fixture(%{game: game_c})
      ownership_fixture(%{game: game_c, entity_name: "Founder", percentage: Decimal.new("80.0")})

      # Get leaderboard data sorted by yield desc
      entries = Games.list_leaderboard_data(%{sort_by: "founder_return", sort_direction: :desc})

      # Verify order: C, A, B
      assert length(entries) == 3
      company_names = Enum.map(entries, & &1.company_name)
      # $1.6M yield
      assert Enum.at(company_names, 0) == "Company C"
      # $1.2M yield
      assert Enum.at(company_names, 1) == "Company A"
      # $0.9M yield
      assert Enum.at(company_names, 2) == "Company B"
    end

    test "list_leaderboard_data/1 respects the limit parameter" do
      # Create multiple games
      user1 = user_fixture(%{email: "user1@example.com"})
      user2 = user_fixture(%{email: "user2@example.com"})
      user3 = user_fixture(%{email: "user3@example.com"})

      for {user, name, value} <- [
            {user1, "Company A", "3000000"},
            {user2, "Company B", "2000000"},
            {user3, "Company C", "1000000"}
          ] do
        game =
          game_fixture(%{
            name: name,
            exit_type: :acquisition,
            exit_value: Decimal.new(value),
            is_public: true,
            is_leaderboard_eligible: true,
            status: :completed,
            user_id: user.id
          })

        _round = round_fixture(%{game: game})
        ownership_fixture(%{game: game, entity_name: "Founder", percentage: Decimal.new("50.0")})
      end

      # Get leaderboard data with limit of 2
      entries = Games.list_leaderboard_data(%{limit: 2})

      # Verify we only get 2 entries
      assert length(entries) == 2
      assert Enum.map(entries, & &1.company_name) == ["Company A", "Company B"]
    end

    test "list_leaderboard_data/1 only returns eligible games" do
      user = user_fixture(%{email: "test@example.com"})

      # Eligible game
      eligible_game =
        game_fixture(%{
          name: "Eligible Company",
          exit_type: :acquisition,
          exit_value: Decimal.new("2000000"),
          is_public: true,
          is_leaderboard_eligible: true,
          status: :completed,
          user_id: user.id
        })

      _eligible_round = round_fixture(%{game: eligible_game})

      ownership_fixture(%{
        game: eligible_game,
        entity_name: "Founder",
        percentage: Decimal.new("50.0")
      })

      # Non-public game
      private_game =
        game_fixture(%{
          name: "Private Company",
          exit_type: :acquisition,
          exit_value: Decimal.new("3000000"),
          is_public: false,
          is_leaderboard_eligible: true,
          status: :completed,
          user_id: user.id
        })

      _private_round = round_fixture(%{game: private_game})

      ownership_fixture(%{
        game: private_game,
        entity_name: "Founder",
        percentage: Decimal.new("50.0")
      })

      # Non-leaderboard eligible game
      ineligible_game =
        game_fixture(%{
          name: "Non-eligible Company",
          exit_type: :acquisition,
          exit_value: Decimal.new("4000000"),
          is_public: true,
          is_leaderboard_eligible: false,
          status: :completed,
          user_id: user.id
        })

      _ineligible_round = round_fixture(%{game: ineligible_game})

      ownership_fixture(%{
        game: ineligible_game,
        entity_name: "Founder",
        percentage: Decimal.new("50.0")
      })

      # Not completed game
      incomplete_game =
        game_fixture(%{
          name: "Incomplete Company",
          is_public: true,
          is_leaderboard_eligible: true,
          status: :in_progress,
          user_id: user.id
        })

      _incomplete_round = round_fixture(%{game: incomplete_game})

      ownership_fixture(%{
        game: incomplete_game,
        entity_name: "Founder",
        percentage: Decimal.new("50.0")
      })

      # Failed game
      failed_game =
        game_fixture(%{
          name: "Failed Company",
          exit_type: :shutdown,
          is_public: true,
          is_leaderboard_eligible: true,
          status: :failed,
          user_id: user.id
        })

      _failed_round = round_fixture(%{game: failed_game})

      ownership_fixture(%{
        game: failed_game,
        entity_name: "Founder",
        percentage: Decimal.new("50.0")
      })

      # Get leaderboard data
      entries = Games.list_leaderboard_data()

      # Verify we only get the eligible game
      assert length(entries) == 1
      assert hd(entries).company_name == "Eligible Company"
    end

    test "calculate_founder_yield handles missing founder ownership" do
      # Create a game without explicit founder ownership
      user = user_fixture(%{email: "test@example.com"})

      game =
        game_fixture(%{
          name: "No Founder",
          exit_type: :acquisition,
          exit_value: Decimal.new("1000000"),
          is_public: true,
          is_leaderboard_eligible: true,
          status: :completed,
          user_id: user.id
        })

      # Create a round but don't create founder ownership
      _round = round_fixture(%{game: game})

      # Get leaderboard data - should use default 50% for yield calculation
      [entry] = Games.list_leaderboard_data()

      # Verify default 50% yield is calculated
      assert Decimal.equal?(entry.yield, Decimal.new("500000"))
    end

    test "list_leaderboard_data/1 respects existing founder_return/ownership structure" do
      user = user_fixture(%{username: "user", default_game_visibility: :public})

      game_fixture_with_ownership(
        %{
          name: "Company A",
          status: :completed,
          exit_type: :acquisition,
          exit_value: Decimal.new("3000000"),
          percentage: Decimal.new("50.0"),
          founder_return: Decimal.new("1500000")
        },
        user
      )

      entries = Games.list_leaderboard_data()
      assert length(entries) == 1
      assert hd(entries).yield == Decimal.new("1500000")
    end
  end

  # Complex business logic tests

  describe "update_ownership_structure/3" do
    test "adds new entities and updates existing ones" do
      game = game_fixture()
      round = round_fixture(%{game: game})

      # Create initial ownership
      ownership_fixture(%{
        game: game,
        entity_name: "Founder",
        percentage: Decimal.new("100.00")
      })

      # Update ownership structure
      new_ownerships = [
        %{entity_name: "Founder", percentage: Decimal.new("80.00")},
        %{entity_name: "Investor", percentage: Decimal.new("20.00")}
      ]

      assert {:ok, updated_ownerships} =
               Games.update_ownership_structure(new_ownerships, game, round)

      assert length(updated_ownerships) == 2

      # Check that ownerships were updated correctly
      ownerships = Games.list_game_ownerships(game.id)
      assert length(ownerships) == 2

      founder = Enum.find(ownerships, fn o -> o.entity_name == "Founder" end)
      investor = Enum.find(ownerships, fn o -> o.entity_name == "Investor" end)

      assert Decimal.equal?(founder.percentage, Decimal.new("80.00"))
      assert Decimal.equal?(investor.percentage, Decimal.new("20.00"))

      # Check that ownership changes were recorded
      changes = Games.list_game_ownership_changes(game.id)
      assert length(changes) == 2

      founder_change = Enum.find(changes, fn c -> c.entity_name == "Founder" end)
      investor_change = Enum.find(changes, fn c -> c.entity_name == "Investor" end)

      assert Decimal.equal?(founder_change.previous_percentage, Decimal.new("100.00"))
      assert Decimal.equal?(founder_change.new_percentage, Decimal.new("80.00"))
      assert founder_change.change_type == :dilution

      assert Decimal.equal?(investor_change.previous_percentage, Decimal.new("0.00"))
      assert Decimal.equal?(investor_change.new_percentage, Decimal.new("20.00"))
      assert investor_change.change_type == :initial
    end

    test "removes entities not in the new structure" do
      game = game_fixture()
      round = round_fixture(%{game: game})

      # Create initial ownerships
      ownership_fixture(%{
        game: game,
        entity_name: "Founder",
        percentage: Decimal.new("80.00")
      })

      ownership_fixture(%{
        game: game,
        entity_name: "Angel",
        percentage: Decimal.new("20.00")
      })

      # Update ownership structure, removing Angel
      new_ownerships = [
        %{entity_name: "Founder", percentage: Decimal.new("70.00")},
        %{entity_name: "VC", percentage: Decimal.new("30.00")}
      ]

      assert {:ok, _} = Games.update_ownership_structure(new_ownerships, game, round)

      # Check that ownerships were updated correctly
      ownerships = Games.list_game_ownerships(game.id)
      assert length(ownerships) == 2

      entity_names = Enum.map(ownerships, & &1.entity_name)
      assert "Founder" in entity_names
      assert "VC" in entity_names
      refute "Angel" in entity_names

      # Check that exit change was recorded
      changes = Games.list_game_ownership_changes(game.id)
      # Founder dilution, VC initial, Angel exit
      assert length(changes) == 3

      angel_exit =
        Enum.find(changes, fn c -> c.entity_name == "Angel" and c.change_type == :exit end)

      assert angel_exit != nil
      assert Decimal.equal?(angel_exit.previous_percentage, Decimal.new("20.00"))
      assert Decimal.equal?(angel_exit.new_percentage, Decimal.new("0.00"))
    end
  end

  describe "create_new_game/2" do
    test "creates a game with user's default visibility settings (private)" do
      user = user_fixture()
      # default value
      assert user.default_game_visibility == :private

      {:ok, game} =
        Games.create_new_game(
          %{
            name: "Test Game",
            description: "A test game"
          },
          user
        )

      assert game.is_public == false
      assert game.is_leaderboard_eligible == false
    end

    test "creates a game with user's default visibility settings (public)" do
      {:ok, user} =
        Accounts.update_user_visibility_settings(
          user_fixture(),
          %{default_game_visibility: :public}
        )

      assert user.default_game_visibility == :public

      {:ok, game} =
        Games.create_new_game(
          %{
            name: "Test Game",
            description: "A test game"
          },
          user
        )

      assert game.is_public == true
      assert game.is_leaderboard_eligible == true
    end

    test "allows overriding visibility settings in game attributes" do
      # defaults to private
      user = user_fixture()
      assert user.default_game_visibility == :private

      {:ok, game} =
        Games.create_new_game(
          %{
            name: "Test Game",
            description: "A test game",
            is_public: true,
            is_leaderboard_eligible: true
          },
          user
        )

      assert game.is_public == true
      assert game.is_leaderboard_eligible == true
    end
  end
end
