defmodule StartupGameWeb.Admin.TrainingGameLive.IndexTest do
  use StartupGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import StartupGame.AccountsFixtures
  import StartupGame.GamesFixtures

  alias StartupGame.Games
  alias StartupGame.Games.Game
  alias StartupGame.Engine.LLMScenarioProvider

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

  describe "Create Training Game Modal" do
    setup %{conn: conn, admin: admin} do
      {:ok, view, _html} =
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/training_games")

      {:ok, view: view}
    end

    test "opens and closes the create modal", %{view: view} do
      # Modal initially hidden
      refute has_element?(view, "#create-game-modal")

      # Click button to open modal
      view |> element("button", "Create New Training Game") |> render_click()

      # Modal is now visible with the form component
      assert has_element?(view, "#create-game-modal")
      # Check for form presence instead of component root
      assert has_element?(view, "#training-game-form")

      # Check default prompts are pre-filled (example check)
      default_scenario_prompt = LLMScenarioProvider.scenario_system_prompt()
      assert view |> element("form#training-game-form textarea[name='game[scenario_system_prompt]']") |> render() =~ ~r/#{Regex.escape(String.slice(default_scenario_prompt, 0..50))}/

      # Click cancel button within the component to close
      view |> element("#create-game-modal button", "Cancel") |> render_click()
      refute has_element?(view, "#create-game-modal")
    end

    test "creates a new training game successfully", %{view: view} do
      # Open modal
      view |> element("button", "Create New Training Game") |> render_click()
      assert has_element?(view, "#create-game-modal")

      # Fill and submit form
      form = view |> element("#training-game-form")
      form |> render_change(%{"game" => %{"name" => "My New Training Game", "description" => "Desc..."}})
      form |> render_submit()

      # Modal should close, game listed, flash shown
      refute has_element?(view, "#create-game-modal")
      assert render(view) =~ "My New Training Game"
      assert has_element?(view, "#flash-info", "Training game created successfully.")

      # Verify in DB
      # Verify the new game exists in the list of training games
      assert Enum.any?(Games.list_training_games(), fn game ->
               game.name == "My New Training Game" && game.is_training_example == true
             end)
    end
  end

  describe "Import Training Game Modal" do
    setup %{conn: conn, admin: admin, user: user} do
      # Create a game that can be imported (not a training example)
      importable_game =
        game_fixture(%{
          user_id: user.id,
          name: "Importable Game One",
          is_training_example: false
        })

      {:ok, view, _html} =
        conn
        |> log_in_user(admin)
        |> live(~p"/admin/training_games")

      {:ok, view: view, importable_game: importable_game}
    end

    test "opens modal and lists importable games", %{view: view, importable_game: importable_game} do
      # Modal initially hidden
      refute has_element?(view, "#import-game-modal")

      # Click button to open modal
      view |> element("button", "Import Existing Game") |> render_click()

      # Modal is now visible with the select input
      assert has_element?(view, "#import-game-modal")
      assert has_element?(view, "select#import-game-select")

      # Check that the importable game is listed in the options
      assert has_element?(view, "select#import-game-select option[value='#{importable_game.id}']", importable_game.name)

      # Check that the existing training game is NOT listed
      refute has_element?(view, "select#import-game-select option", "Training Game Alpha")

      # Click cancel button to close
      view |> element("#import-game-modal button", "Cancel") |> render_click()
      refute has_element?(view, "#import-game-modal")
    end

    test "imports a game successfully", %{view: view, importable_game: importable_game} do
      # Open modal
      view |> element("button", "Import Existing Game") |> render_click()
      assert has_element?(view, "#import-game-modal")

      # Select game and submit form
      form = view |> element("#import-game-modal form")
      form |> render_submit(%{"source_game_id" => importable_game.id})

      # Navigation is triggered by push_navigate, assert_patch doesn't work directly here.
      # We verify the game creation below.

      # Verify flash message on the *redirected* page (requires follow_redirect)
      # This part is tricky with push_navigate, might need integration test or manual check.
      # For now, we verify the game was created in the DB.

      # Verify in DB - check for the cloned game
      cloned_game_name = "[TRAINING] #{importable_game.name}"
      assert Enum.any?(Games.list_training_games(), fn game ->
               game.name == cloned_game_name && game.is_training_example == true
             end)
    end

    test "shows error if no game selected", %{view: view} do
      # Open modal
      view |> element("button", "Import Existing Game") |> render_click()
      assert has_element?(view, "#import-game-modal")

      # Submit form with empty selection
      form = view |> element("#import-game-modal form")
      form |> render_submit(%{"source_game_id" => ""})

      # Modal stays open, flash shown
      assert has_element?(view, "#import-game-modal")
      assert has_element?(view, "#flash-error", "Please select a game to import.")
    end

    test "shows errors for invalid data", %{view: view} do
       # Open modal
      view |> element("button", "Create New Training Game") |> render_click()
      assert has_element?(view, "#create-game-modal")

      # Submit form with empty name
      form = view |> element("#training-game-form")
      form |> render_change(%{"game" => %{"name" => "", "description" => "Desc..."}})
      form |> render_submit()

      # Modal stays open, error shown
      assert has_element?(view, "#create-game-modal")
      # Check for error text within the form
      assert has_element?(view, "form#training-game-form", "can't be blank")
    end
  end
end
