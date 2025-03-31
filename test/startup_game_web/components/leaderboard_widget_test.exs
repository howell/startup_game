defmodule StartupGameWeb.LeaderboardWidgetTest do
  use StartupGameWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import StartupGame.GamesFixtures
  import StartupGame.AccountsFixtures
  alias StartupGame.Games

  alias StartupGameWeb.LeaderboardWidget

  describe "LeaderboardWidget" do
    setup do
      user = user_fixture(%{email: "test@example.com", username: "testuser"})

      # Create a regular (non-case study) game
      game =
        game_fixture_with_ownership(
          %{
            name: "Test Company",
            description: "A test company",
            status: :completed,
            exit_type: :acquisition,
            exit_value: Decimal.new("2000000"),
            percentage: Decimal.new("50.0"),
            is_public: true,
            is_leaderboard_eligible: true,
            is_case_study: false
          },
          user
        )

      # Create a round to ensure the game is valid
      _round = round_fixture(game)

      # Ensure is_case_study is correctly set
      {:ok, _} = Games.update_game(game, %{is_case_study: false})

      # Create a case study game with higher exit value
      case_study_user =
        user_fixture(%{email: "case_study@example.com", username: "case_study_user"})

      case_study_game =
        game_fixture_with_ownership(
          %{
            name: "Case Study Company",
            description: "A case study company",
            status: :completed,
            exit_type: :acquisition,
            exit_value: Decimal.new("5000000"),
            percentage: Decimal.new("50.0"),
            is_public: true,
            is_leaderboard_eligible: true,
            is_case_study: true
          },
          case_study_user
        )

      _case_study_round = round_fixture(case_study_game)

      # Directly update is_case_study in the database
      {:ok, _} = Games.update_game(case_study_game, %{is_case_study: true})

      %{
        user: user,
        game: game,
        case_study_user: case_study_user,
        case_study_game: case_study_game
      }
    end

    test "renders the leaderboard with game links", %{game: game} do
      html =
        render_component(&LeaderboardWidget.render/1, %{
          id: "test-leaderboard",
          limit: 10,
          sort_by: "exit_value",
          sort_direction: :desc,
          include_case_studies: false,
          leaderboard_data:
            StartupGame.Games.list_leaderboard_data(%{include_case_studies: false}),
          myself: nil
        })

      # Assert that the game's name is rendered
      assert html =~ "Test Company"

      # Assert that there's a link to the game view page
      assert html =~ ~s{href="/games/view/#{game.id}"}
    end

    test "renders the username for each entry", %{user: user} do
      html =
        render_component(&LeaderboardWidget.render/1, %{
          id: "test-leaderboard",
          limit: 10,
          sort_by: "exit_value",
          sort_direction: :desc,
          include_case_studies: false,
          leaderboard_data:
            StartupGame.Games.list_leaderboard_data(%{include_case_studies: false}),
          myself: nil
        })

      # Assert that the username associated with the fixture user is rendered
      assert html =~ "@#{user.username}"
    end

    test "includes case studies when include_case_studies is true", %{
      case_study_game: case_study_game
    } do
      # Get leaderboard data with include_case_studies: true
      leaderboard_data = Games.list_leaderboard_data(%{include_case_studies: true})

      # Verify there's at least one case study in the results
      case_study_entries = Enum.filter(leaderboard_data, & &1.is_case_study)
      assert length(case_study_entries) > 0

      # Render the widget with the data
      html =
        render_component(&LeaderboardWidget.render/1, %{
          id: "test-leaderboard",
          limit: 10,
          sort_by: "exit_value",
          sort_direction: :desc,
          include_case_studies: true,
          leaderboard_data: leaderboard_data,
          myself: nil
        })

      # Assert that the case study's name is rendered
      assert html =~ "Case Study Company"
      # Assert that there's a link to the case study game view page
      assert html =~ ~s{href="/games/view/#{case_study_game.id}"}
    end

    test "excludes case studies when include_case_studies is false", %{
      case_study_game: case_study_game
    } do
      # Get leaderboard data with include_case_studies: false
      leaderboard_data = Games.list_leaderboard_data(%{include_case_studies: false})

      # Verify there are no case studies in the results
      case_study_entries = Enum.filter(leaderboard_data, & &1.is_case_study)
      assert Enum.empty?(case_study_entries)

      # The data shouldn't include case study games, so the widget shouldn't render them
      html =
        render_component(&LeaderboardWidget.render/1, %{
          id: "test-leaderboard",
          limit: 10,
          sort_by: "exit_value",
          sort_direction: :desc,
          include_case_studies: false,
          leaderboard_data: leaderboard_data,
          myself: nil
        })

      # Assert that the case study's name is not rendered
      refute html =~ "Case Study Company"
      # Assert that there's no link to the case study game view page
      refute html =~ ~s{href="/games/view/#{case_study_game.id}"}
    end

    test "respects the limit when including case studies" do
      # Create multiple regular games with decreasing exit values
      regular_games =
        for i <- 1..6 do
          user = user_fixture(%{email: "user#{i}@example.com", username: "user#{i}"})

          game =
            game_fixture_with_ownership(
              %{
                name: "Regular Company #{i}",
                description: "A regular company #{i}",
                status: :completed,
                exit_type: :acquisition,
                exit_value: Decimal.new("#{2_000_000 - i * 100_000}"),
                percentage: Decimal.new("50.0"),
                is_public: true,
                is_leaderboard_eligible: true
              },
              user
            )

          _round = round_fixture(game)

          # Explicitly set is_case_study to false
          {:ok, game} = Games.update_game(game, %{is_case_study: false})
          game
        end

      # Create multiple case study games with very high exit values
      case_study_games =
        for i <- 1..3 do
          user = user_fixture(%{email: "case_study#{i}@example.com", username: "case_study#{i}"})

          game =
            game_fixture_with_ownership(
              %{
                name: "Case Study #{i}",
                description: "A case study #{i}",
                status: :completed,
                exit_type: :acquisition,
                exit_value: Decimal.new("#{10_000_000 - i * 1_000_000}"),
                percentage: Decimal.new("50.0"),
                is_public: true,
                is_leaderboard_eligible: true
              },
              user
            )

          _round = round_fixture(game)

          # Explicitly set is_case_study to true
          {:ok, game} = Games.update_game(game, %{is_case_study: true})
          game
        end

      # Verify we've created the expected games
      assert length(regular_games) == 6
      assert length(case_study_games) == 3

      # Verify all case study games have is_case_study set to true
      for game <- case_study_games do
        updated_game = Games.get_game!(game.id)

        assert updated_game.is_case_study == true,
               "Case study game #{updated_game.name} should have is_case_study set to true"
      end

      # Fetch leaderboard data with limit of 5, including case studies
      leaderboard_data =
        Games.list_leaderboard_data(%{
          limit: 5,
          include_case_studies: true,
          sort_by: "exit_value",
          sort_direction: :desc
        })

      # We should have exactly 5 total entries
      assert length(leaderboard_data) == 5

      # Count case studies in the results
      case_study_count = Enum.count(leaderboard_data, & &1.is_case_study)

      assert case_study_count == 4

      # Regular games should fill the rest of the limit
      regular_count = length(leaderboard_data) - case_study_count

      assert regular_count == 1

      # Check that the case studies are actually in the results
      case_study_names =
        Enum.filter(leaderboard_data, & &1.is_case_study) |> Enum.map(& &1.company_name)

      assert Enum.all?(case_study_names, &(&1 =~ "Case Study"))
    end
  end
end
