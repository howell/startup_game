defmodule StartupGameWeb.GameLive.Play.AuthorizationTest do
  use StartupGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import StartupGame.{GamesFixtures, AccountsFixtures}

  describe "Play LiveView - authorization" do
    test "only allows game owner to access their game", %{conn: conn} do
      # Create two users
      owner = user_fixture()
      other_user = user_fixture()

      # Create a game owned by the first user
      game = game_fixture(%{name: "Owner's Game", description: "Test Description"}, owner)

      # Owner should be able to access their game
      conn_as_owner = log_in_user(conn, owner)
      {:ok, _view, _html} = live(conn_as_owner, ~p"/games/play/#{game.id}")

      # Other user should be redirected when trying to access someone else's game
      conn_as_other = log_in_user(build_conn(), other_user)

      # Check that the non-owner gets an error and is redirected
      assert {:error, {:redirect, %{to: "/games"}}} =
               live(conn_as_other, ~p"/games/play/#{game.id}")
    end

    test "unauthenticated user cannot access a game", %{conn: conn} do
      # Create a user and game
      user = user_fixture()
      game = game_fixture(%{name: "Private Game"}, user)

      # Unauthenticated user should be redirected to login
      assert {:error, {:redirect, %{to: "/users/log_in"}}} =
               live(conn, ~p"/games/play/#{game.id}")
    end

    test "public games can be viewed by other users in view mode", %{conn: conn} do
      # Create owner and viewer users
      owner = user_fixture()
      viewer = user_fixture()

      # Create a public game
      game = game_fixture(%{name: "Public Game", is_public: true}, owner)

      # Owner can access the game normally
      owner_conn = log_in_user(conn, owner)
      {:ok, _owner_view, owner_html} = live(owner_conn, ~p"/games/play/#{game.id}")

      # Check that owner has control elements
      assert owner_html =~ "Respond to the situation"

      # Viewer can see the game in view mode
      viewer_conn = log_in_user(build_conn(), viewer)
      {:ok, _viewer_view, viewer_html} = live(viewer_conn, ~p"/games/view/#{game.id}")

      # Check that viewer doesn't have control elements
      assert viewer_html =~ "Public Game"
      assert viewer_html =~ "Game in progress"
      refute viewer_html =~ "Respond to the situation"
    end
  end
end
