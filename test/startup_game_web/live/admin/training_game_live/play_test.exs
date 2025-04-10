defmodule StartupGameWeb.Admin.TrainingGameLive.PlayTest do
  use StartupGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import StartupGame.AccountsFixtures
  import StartupGame.GamesFixtures

  @admin_attrs %{email: "admin@example.com", password: "password1234", role: :admin}
  @user_attrs %{email: "user@example.com", password: "password1234", role: :user}

  setup do
    admin = user_fixture(@admin_attrs)
    user = user_fixture(@user_attrs)

    # Create a training game with some rounds
    training_game =
      game_fixture_with_rounds(2, %{
        user_id: admin.id,
        name: "Playable Training Game",
        is_training_example: true
      })

    # Create a regular game
    regular_game =
      game_fixture(%{user_id: user.id, name: "Regular Play Game", is_training_example: false})

    {:ok, admin: admin, user: user, training_game: training_game, regular_game: regular_game}
  end

  describe "Play page" do
    test "allows admin to view a training game", %{
      conn: conn,
      admin: admin,
      training_game: training_game
    } do
      {:ok, _view, html} =
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/training_games/#{training_game.id}/play")

      assert html =~ training_game.name
      assert html =~ "Game History"
      # Check if round details are present (example check)
      assert html =~ "Situation:"
      assert html =~ "Player Input:"
      assert html =~ "Outcome:"
      # From game_fixture_with_rounds
      assert html =~ "Response for round 1"
      assert html =~ "Response for round 2"
    end

    test "redirects admin if accessing non-training game", %{
      conn: conn,
      admin: admin,
      regular_game: regular_game
    } do
      response =
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/training_games/#{regular_game.id}/play")

      assert {:error, {:redirect, info}} = response
      assert info.to == "/admin/training_games"
      assert info.flash == %{"error" => "Game not found or not a training game"}
    end

    test "redirects non-admin users", %{conn: conn, user: user, training_game: training_game} do
      conn =
        conn
        |> log_in_user(user)
        # Use get for redirect check
        |> get(~p"/admin/training_games/#{training_game.id}/play")

      # Should redirect to root due to RequireAdminAuth plug
      assert redirected_to(conn) == "/"
    end

    test "redirects unauthenticated users", %{conn: conn, training_game: training_game} do
      # Use get for redirect check
      conn = get(conn, ~p"/admin/training_games/#{training_game.id}/play")
      # Should redirect somewhere (likely login)
      assert redirected_to(conn)
    end
  end
end
