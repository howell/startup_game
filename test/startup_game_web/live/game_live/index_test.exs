defmodule StartupGameWeb.GameLive.IndexTest do
  use StartupGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import StartupGame.AccountsFixtures

  alias StartupGame.Games

  @create_attrs %{
    name: "Test Game",
    description: "A test game description",
    cash_on_hand: 10_000.0,
    burn_rate: 1000.0
  }

  defp create_user_and_game(_) do
    user = user_fixture()
    {:ok, game} = Games.create_new_game(@create_attrs, user)
    %{user: user, game: game}
  end

  describe "Index" do
    setup [:create_user_and_game]

    test "lists all user games", %{conn: conn, user: user, game: game} do
      conn = log_in_user(conn, user)
      {:ok, _index_live, html} = live(conn, ~p"/games")

      assert html =~ "My Startup Games"
      assert html =~ game.name
    end

    test "can toggle game visibility settings", %{conn: conn, user: user, game: game} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/games")

      # Check initial visibility settings
      assert game.is_public == false
      assert game.is_leaderboard_eligible == false

      # Toggle public visibility using ID
      view
      |> element("#game-public-toggle-#{game.id}")
      |> render_click()

      # Verify game was updated
      updated_game = Games.get_game!(game.id)
      assert updated_game.is_public == true
      assert updated_game.is_leaderboard_eligible == false

      # Toggle leaderboard eligibility using ID
      view
      |> element("#game-leaderboard-toggle-#{game.id}")
      |> render_click()

      # Verify game was updated again
      updated_game = Games.get_game!(game.id)
      assert updated_game.is_public == true
      assert updated_game.is_leaderboard_eligible == true
    end
  end
end
