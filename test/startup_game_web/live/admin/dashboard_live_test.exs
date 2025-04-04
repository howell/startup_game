defmodule StartupGameWeb.Admin.DashboardLiveTest do
  use StartupGameWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias StartupGame.AccountsFixtures
  alias StartupGame.GamesFixtures

  @moduletag :admin

  describe "Admin Dashboard" do
    setup :register_and_log_in_admin

    test "renders dashboard with initial stats, links, and tables", %{
      conn: conn,
      admin_user: admin
    } do
      {:ok, view, _initial_html} = live(conn, ~p"/admin")
      # Header and Subtitle
      assert has_element?(view, "h1", "Admin Dashboard")
      assert has_element?(view, "p", "Overview and management tools.")

      assert element(view, "#total-users-card dd") |> render() =~ "1"

      assert element(view, "#total-games-card dd") |> render() =~ "0"

      # Management Links
      assert has_element?(view, ~s|a[href="/admin/users"]|, "Manage Users")
      assert has_element?(view, ~s|a[href="/admin/games"]|, "Manage Games")

      # Recent Users Table (Should contain the logged-in admin)
      assert has_element?(view, "#recent-users")
      # Target specific row and cell for admin user
      first_row = element(view, "#recent-users tr") |> render()
      assert first_row =~ admin.username
      assert first_row =~ admin.email
      assert first_row =~ "admin"

      # Recent Games Table (Should be empty initially)
      assert has_element?(view, "#recent-games")
      refute has_element?(view, "#recent-games tr")
    end

    test "displays newly created users and games", %{conn: conn, admin_user: admin} do
      # Create additional data
      _user2 = AccountsFixtures.user_fixture(%{email: "test@example.com", username: "tester"})
      _game1 = GamesFixtures.game_fixture(%{user_id: admin.id, name: "Admin's Game"})

      {:ok, view, _initial_html} = live(conn, ~p"/admin")

      assert element(view, "#total-users-card dd") |> render() =~ "2"

      assert element(view, "#total-games-card dd") |> render() =~ "1"
    end
  end
end
