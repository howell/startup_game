defmodule StartupGameWeb.Admin.TrainingGameLive.PlayTest do
  use StartupGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import StartupGame.AccountsFixtures
  import StartupGame.GamesFixtures
  alias StartupGame.Games

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

  describe "Edit Outcome Modal" do
    setup %{conn: conn, admin: admin, training_game: original_training_game} do
      # Reload game with associations for the test setup
      training_game = Games.get_game_with_associations!(original_training_game.id)

      {:ok, view, _html} =
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/training_games/#{training_game.id}/play")

      # Get the ID of the first round
      first_round_id = hd(training_game.rounds).id
      {:ok, view: view, first_round_id: first_round_id, training_game: training_game}
    end

    test "opens and closes the edit modal", %{view: view, first_round_id: first_round_id} do
      # Modal initially hidden
      refute has_element?(view, "#edit-outcome-modal")

      # Click edit button for the first round
      view
      |> element("button[phx-value-round_id='#{first_round_id}']", "Edit")
      |> render_click()

      # Process.sleep(100)

      # Modal is now visible with the form component
      assert has_element?(view, "#edit-outcome-modal")
      assert has_element?(view, "#edit-outcome-form-#{first_round_id}")

      # Check original outcome is pre-filled (example check)
      assert view
             |> element("#edit-outcome-form-#{first_round_id} textarea[name='round[outcome]']")
             |> render() =~ "Outcome for round 1"

      # Click cancel button within the component to close
      view |> element("#edit-outcome-modal button", "Cancel") |> render_click()
      refute has_element?(view, "#edit-outcome-modal")
    end

    test "updates round outcome successfully", %{view: view, first_round_id: first_round_id} do
      # Open modal
      view
      |> element("button[phx-value-round_id='#{first_round_id}']", "Edit")
      |> render_click()

      assert has_element?(view, "#edit-outcome-modal")

      # Fill and submit form
      form = view |> element("#edit-outcome-form-#{first_round_id}")

      form
      |> render_change(%{
        "round" => %{"outcome" => "Updated Outcome Text", "cash_change" => "1234.56"}
      })

      form |> render_submit()

      # Modal should close, flash shown, outcome updated in view
      refute has_element?(view, "#edit-outcome-modal")
      assert has_element?(view, "#flash-info", "Round outcome updated successfully.")
      assert render(view) =~ "Updated Outcome Text"
      assert render(view) =~ "Cash Change: 1234.56"

      # Verify in DB
      updated_round = Games.get_round!(first_round_id)
      assert updated_round.outcome == "Updated Outcome Text"
      assert Decimal.equal?(updated_round.cash_change, Decimal.new("1234.56"))
    end

    test "shows errors for invalid outcome data", %{view: view, first_round_id: first_round_id} do
      # Open modal
      view
      |> element("button[phx-value-round_id='#{first_round_id}']", "Edit")
      |> render_click()

      assert has_element?(view, "#edit-outcome-modal")

      # Submit form with invalid cash_change
      form = view |> element("#edit-outcome-form-#{first_round_id}")
      form |> render_change(%{"round" => %{"cash_change" => "not-a-number"}})
      form |> render_submit()

      # Modal stays open, error shown
      assert has_element?(view, "#edit-outcome-modal")
      # Check for generic decimal error
      assert has_element?(view, "form#edit-outcome-form-#{first_round_id}", "is invalid")
    end
  end
end
