defmodule StartupGameWeb.LeaderboardWidgetTest do
  use StartupGameWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import StartupGame.GamesFixtures
  import StartupGame.AccountsFixtures

  alias StartupGameWeb.LeaderboardWidget

  describe "LeaderboardWidget" do
    setup do
      user = user_fixture(%{email: "test@example.com"})

      # Create a game eligible for the leaderboard
      game =
        game_fixture_with_ownership(%{
          name: "Test Company",
          description: "A test company",
          status: :completed,
          exit_type: :acquisition,
          exit_value: Decimal.new("2000000"),
          percentage: Decimal.new("50.0"),
          is_public: true,
          is_leaderboard_eligible: true,
          user_id: user.id
        })

      # Create a round to ensure the game is valid
      _round = round_fixture(game)

      %{
        user: user,
        game: game
      }
    end

    test "renders the leaderboard with game links", %{game: game} do
      html =
        render_component(&LeaderboardWidget.render/1, %{
          id: "test-leaderboard",
          limit: 10,
          sort_by: "exit_value",
          sort_direction: :desc,
          leaderboard_data: StartupGame.Games.list_leaderboard_data(),
          myself: nil
        })

      # Assert that the game's name is rendered
      assert html =~ "Test Company"

      # Assert that there's a link to the game view page
      assert html =~ ~s{href="/games/view/#{game.id}"}
    end
  end
end
