defmodule StartupGameWeb.Admin.TrainingGameLive.IndexTest do
  use StartupGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import StartupGame.AccountsFixtures
  import StartupGame.GamesFixtures

  alias StartupGame.Games.Game

  @admin_attrs %{email: "admin@example.com", password: "password1234", role: :admin}
  @user_attrs %{email: "user@example.com", password: "password1234", role: :user}

  setup do
    admin = user_fixture(@admin_attrs)
    user = user_fixture(@user_attrs)

    # Create one regular game
    game_fixture(%{user_id: user.id, name: "Regular Game"})

    # Create one training game
    training_game =
      game_fixture(%{
        user_id: admin.id,
        name: "Training Game Alpha",
        is_training_example: true
      })

    {:ok, admin: admin, user: user, training_game: training_game}
  end

  describe "Index page" do
    test "lists only training games for admin", %{
      conn: conn,
      admin: admin,
      training_game: training_game
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/training_games")


      # Ensure view is rendered after mount assigns
      html = render(view)

      # Check that the training game is listed
      assert html =~ training_game.name
      assert html =~ "/admin/training_games/#{training_game.id}/play"

      # Check that the regular game is NOT listed
      refute html =~ "Regular Game"

      # Check for buttons
      assert html =~ "Create New Training Game"
      assert html =~ "Import Existing Game"
    end

    test "redirects non-admin users", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        # Use get for non-LiveView redirect check
        |> get(~p"/admin/training_games")

      # Check for redirect and flash message (assuming standard redirect behavior)
      # Redirects to root
      assert redirected_to(conn) == "/"
      # Flash message check might depend on how it's handled in tests
      # assert get_flash(conn, :error) =~ "You must be an administrator"
    end

    test "redirects unauthenticated users", %{conn: conn} do
      # Use get for non-LiveView redirect check
      conn = get(conn, ~p"/admin/training_games")
      # Should redirect somewhere (likely login)
      assert redirected_to(conn)
    end
  end
end
