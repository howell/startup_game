defmodule StartupGameWeb.GameLive.ViewTest do
  use StartupGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import StartupGame.GamesFixtures
  import StartupGame.AccountsFixtures

  describe "View LiveView - public games" do
    setup do
      user = user_fixture()

      # Create a public game
      public_game =
        game_fixture(
          %{
            name: "Public Game",
            description: "A public game",
            is_public: true
          },
          user
        )

      # Create a private game
      private_game =
        game_fixture(
          %{
            name: "Private Game",
            description: "A private game",
            is_public: false
          },
          user
        )

      %{
        user: user,
        public_game: public_game,
        private_game: private_game
      }
    end

    test "renders public game information when game is public", %{conn: conn, public_game: game} do
      {:ok, _view, html} = live(conn, ~p"/games/view/#{game.id}")

      assert html =~ "Public Game"
      assert html =~ "A public game"
      assert html =~ "Cash"
      assert html =~ "Burn Rate"
      assert html =~ "OWNERSHIP STRUCTURE"
      assert html =~ "Game in progress"
    end

    test "redirects when game doesn't exist", %{conn: conn} do
      non_existent_id = "00000000-0000-0000-0000-000000000000"

      assert {:error,
              {:redirect, %{to: "/", flash: %{"error" => "Game not found or not public"}}}} =
               live(conn, ~p"/games/view/#{non_existent_id}")
    end

    test "redirects when game is not public", %{conn: conn, private_game: game} do
      assert {:error,
              {:redirect, %{to: "/", flash: %{"error" => "Game not found or not public"}}}} =
               live(conn, ~p"/games/view/#{game.id}")
    end

    test "does not render visibility settings section", %{conn: conn, public_game: game} do
      {:ok, view, _html} = live(conn, ~p"/games/view/#{game.id}")

      # Verify visibility settings section is not present
      refute has_element?(view, "h3", "VISIBILITY SETTINGS")
      refute has_element?(view, "[data-test-id='visibility-setting']")
      refute has_element?(view, "h3", "Game Visibility")

      # Verify toggle elements are not present
      refute has_element?(view, "#game-public-toggle-main")
      refute has_element?(view, "#game-leaderboard-toggle-main")
    end

    test "does not render chat response form", %{conn: conn, public_game: game} do
      {:ok, view, _html} = live(conn, ~p"/games/view/#{game.id}")

      # Check textarea and submit button aren't present
      refute has_element?(view, "textarea[name='response']")
      refute has_element?(view, "button[type='submit']")

      # Verify view-only message is shown instead
      assert has_element?(view, "p", ~r/Game in progress/)
      assert has_element?(view, "a", "Click here to play")
    end

    test "does not render provider selector", %{conn: conn, public_game: game} do
      {:ok, view, _html} = live(conn, ~p"/games/view/#{game.id}")

      # Check that provider selector elements aren't present
      refute has_element?(view, "h3", "SCENARIO PROVIDER")
      refute has_element?(view, "button", "Static Demo")
      refute has_element?(view, "button", "OpenAI GPT")
    end

    test "cannot trigger game actions", %{conn: conn, public_game: game} do
      {:ok, view, _html} = live(conn, ~p"/games/view/#{game.id}")

      # Try to submit a response and verify it fails or is ignored
      assert_raise ArgumentError,
                   ~r/expected selector.*to return a single element, but got none/,
                   fn ->
                     view
                     |> element("form[phx-submit='submit_response']")
                     |> render_submit(%{"response" => "Test response"})
                   end

      # Try to toggle visibility and verify it fails or is ignored
      assert_raise ArgumentError,
                   ~r/expected selector.*to return a single element, but got none/,
                   fn ->
                     view
                     |> element("input[phx-click='toggle_visibility']")
                     |> render_click()
                   end
    end
  end

  describe "View LiveView - mobile UI" do
    setup do
      user = user_fixture()

      # Create a public game
      public_game =
        game_fixture(
          %{
            name: "Public Game",
            description: "A public game",
            is_public: true
          },
          user
        )

      %{
        user: user,
        public_game: public_game
      }
    end

    test "renders condensed game state panel", %{conn: conn, public_game: game} do
      {:ok, _view, html} = live(conn, ~p"/games/view/#{game.id}")

      # Check that the mobile panel container exists
      assert html =~ "mobile-condensed-panel"

      # Panel content should include financial information
      assert html =~ "$10.0k"
      assert html =~ "hero-currency-dollar"
      assert html =~ "hero-fire"
      assert html =~ "hero-clock"
    end

    test "can toggle mobile state visibility", %{conn: conn, public_game: game} do
      {:ok, view, _html} = live(conn, ~p"/games/view/#{game.id}")

      view
      |> element(
        "#mobile-condensed-panel [aria-expanded='false'][phx-click='toggle_panel_expansion']"
      )
      |> render_click()

      mobile_panel_expanded_html = element(view, "#mobile-condensed-panel") |> render()
      assert mobile_panel_expanded_html =~ "hero-chevron-up-mini"
      assert mobile_panel_expanded_html =~ "FINANCES"
      # Collapse again - click button in expanded panel header
      view
      |> element(
        "#mobile-condensed-panel [aria-expanded='true'][phx-click='toggle_panel_expansion']"
      )
      |> render_click()

      mobile_panel_collapsed_again_html = element(view, "#mobile-condensed-panel") |> render()
      assert mobile_panel_collapsed_again_html =~ "hero-chevron-down-mini"
      refute mobile_panel_collapsed_again_html =~ "FINANCES"
    end

    test "does not render settings button", %{conn: conn, public_game: game} do
      {:ok, view, html} = live(conn, ~p"/games/view/#{game.id}")

      # Settings button should not be present in view mode
      refute html =~ "toggle_settings_modal"
      refute html =~ "Settings"

      view
      |> element(
        "#mobile-condensed-panel [aria-expanded='false'][phx-click='toggle_panel_expansion']"
      )
      |> render_click()

      refute html =~ "Settings"
      refute has_element?(view, "button", "Settings")
    end
  end
end
