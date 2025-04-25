defmodule StartupGameWeb.GameLive.Play.BasicTest do
  use StartupGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import StartupGame.{AccountsFixtures, GamesFixtures}

  alias StartupGame.Games

  @create_attrs %{
    name: "Test Game",
    description: "A test game description",
    cash_on_hand: 10_000.0,
    burn_rate: 1000.0,
    start?: true
  }

  defp create_user_and_game(_) do
    user = user_fixture()
    game = game_fixture(@create_attrs, user)
    %{user: user, game: game}
  end

  describe "Play LiveView - basic UI" do
    setup [:create_user_and_game]

    test "renders game play interface", %{conn: conn, user: user, game: game} do
      conn = log_in_user(conn, user)
      {:ok, _play_live, html} = live(conn, ~p"/games/play/#{game.id}")

      assert html =~ game.name
      assert html =~ game.description
    end

    test "can toggle game visibility settings", %{conn: conn, user: user, game: game} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")

      # Check initial visibility settings
      assert game.is_public == false
      assert game.is_leaderboard_eligible == false

      # Toggle public visibility using ID with prefix
      view
      |> element("#game-public-toggle-main")
      |> render_click()

      # Verify game was updated
      updated_game = Games.get_game!(game.id)
      assert updated_game.is_public == true
      assert updated_game.is_leaderboard_eligible == false

      # Toggle leaderboard eligibility using ID with prefix
      view
      |> element("#game-leaderboard-toggle-main")
      |> render_click()

      # Verify game was updated again
      updated_game = Games.get_game!(game.id)
      assert updated_game.is_public == true
      assert updated_game.is_leaderboard_eligible == true
    end
  end

  describe "Play LiveView - helper functions" do
    setup [:create_user_and_game]

    test "format_money formats decimal values correctly", %{conn: conn, user: user, game: game} do
      {:ok, game} =
        Games.update_game(game, %{
          cash_on_hand: Decimal.new("12345.67"),
          burn_rate: Decimal.new("1234.56"),
          start?: false
        })

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      # Cash on hand
      assert html =~ "$12.3k"
      # Burn rate
      assert html =~ "$1.2k"
    end

    test "format_percentage formats decimal values correctly", %{
      conn: conn,
      user: user,
      game: game
    } do
      ownership_fixture(game, %{entity_name: "Test Entity", percentage: Decimal.new("12.34")})

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      # Percentage with one decimal place
      assert html =~ "12.3%"
    end

    test "format_runway formats decimal values correctly", %{conn: conn, user: user, game: game} do
      {:ok, game} =
        Games.update_game(game, %{
          cash_on_hand: Decimal.new("10000.00"),
          burn_rate: Decimal.new("3333.33")
        })

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      # Runway (10000/3333.33 ≈ 3.0)
      assert html =~ "3"
    end
  end
end
