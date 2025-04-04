defmodule StartupGameWeb.Admin.GameManagementLiveTest do
  use StartupGameWeb.ConnCase, async: true
  # Ensure standard import
  import Phoenix.LiveViewTest
  import Phoenix.LiveViewTest
  import StartupGame.AccountsFixtures
  import StartupGame.GamesFixtures

  @moduletag :admin

  describe "Admin Game Management" do
    setup :register_and_log_in_admin

    test "renders game management page with games", %{conn: conn, admin_user: admin} do
      # Create a game owned by the admin
      game1 = game_fixture(%{name: "Admin Game"}, admin)
      # Create a game owned by another user
      other_user = user_fixture()
      game2 = game_fixture(%{name: "Other User Game"}, other_user)

      {:ok, view, _html} = live(conn, ~p"/admin/games")

      assert has_element?(view, "h1", "Manage Games")
      # Check table exists
      assert has_element?(view, "#games")

      # Check both games are listed
      assert has_element?(view, "#games tr[id^='game-#{game1.id}'] td", game1.name)
      assert has_element?(view, "#games tr[id^='game-#{game1.id}'] td", admin.username)

      assert has_element?(view, "#games tr[id^='game-#{game2.id}'] td", game2.name)
      # Owner email/username
      assert has_element?(view, "#games tr[id^='game-#{game2.id}'] td", other_user.username)
    end

    # Prefix unused admin
    test "can delete a game", %{conn: conn, admin_user: _admin} do
      # Create a game to delete
      user_owner = user_fixture(%{email: "owner@example.com"})
      game_to_delete = game_fixture(%{user_id: user_owner.id, name: "Game To Delete"})
      game_id_selector = "#games tr[id^='game-#{game_to_delete.id}']"
      modal_selector = "#delete-game-modal"

      {:ok, view, _html} = live(conn, ~p"/admin/games")

      # Ensure game exists initially
      assert has_element?(view, game_id_selector)

      delete_link =
        view
        |> element(
          ~s|#{game_id_selector} a|,
          "Delete"
        )

      updated_html = delete_link |> render_click()

      assert updated_html =~ "Are you sure you want to delete game"
      assert updated_html =~ game_to_delete.name

      updated_html =
        view
        |> element(~s|#{modal_selector} button|, "Delete Game")
        |> render_click()

      assert updated_html =~ "deleted successfully"

      refute has_element?(view, game_id_selector)
    end
  end
end
