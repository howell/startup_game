defmodule StartupGameWeb.GameLive.Play.MobileUITest do
  use StartupGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import StartupGame.GamesFixtures

  alias StartupGame.Games

  describe "Play LiveView - mobile panel and settings modal state" do
    setup :register_and_log_in_user

    test "default state shows collapsed panel and no modal", %{conn: conn, user: user} do
      game = game_fixture(%{}, user)
      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")
      # Check panel state within the mobile panel container
      mobile_panel_html = element(view, "#mobile-condensed-panel") |> render()
      assert mobile_panel_html =~ "hero-chevron-down-mini"
      refute mobile_panel_html =~ "FINANCES"
      # Modal not present anywhere
      refute render(view) =~ "Game Settings"
    end

    test "toggle_panel_expansion event toggles expanded/collapsed panel", %{
      conn: conn,
      user: user
    } do
      game = game_fixture(%{}, user)
      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")
      # Initially collapsed
      mobile_panel_collapsed_html = element(view, "#mobile-condensed-panel") |> render()
      assert mobile_panel_collapsed_html =~ "hero-chevron-down-mini"
      refute mobile_panel_collapsed_html =~ "FINANCES"
      # Expand - click button in collapsed panel
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

    test "toggle_settings_modal event toggles modal open/close", %{conn: conn, user: user} do
      game = game_fixture(%{}, user)
      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")
      # Modal not present initially
      refute render(view) =~ "Game Settings"

      # 1. Expand the mobile panel - target the specific button in the collapsed panel
      expand_button = element(view, "#mobile-condensed-panel button[aria-expanded='false']")
      expand_button |> render_click()

      # 2. Assert the Settings button is now present in the expanded panel
      assert has_element?(view, "#mobile-condensed-panel button", "Settings")

      # 3. Find and click the settings button within the expanded panel footer
      settings_button =
        element(view, "#mobile-condensed-panel button", "Settings")

      # Verify button exists before clicking
      assert render(settings_button) =~ "Settings"
      settings_button |> render_click()

      # 4. Assert Modal is Open
      assert render(view) =~ "Game Settings"

      # 5. Close modal by pushing the toggle_settings_modal event directly
      view |> render_click("toggle_settings_modal")

      refute render(view) =~ "Game Settings"
    end

    test "select_settings_tab event switches modal tabs", %{conn: conn, user: user} do
      game = game_fixture(%{}, user)
      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")
      # Expand the mobile panel first - click button in collapsed panel
      view
      |> element(
        "#mobile-condensed-panel [aria-expanded='false'][phx-click='toggle_panel_expansion']"
      )
      |> render_click()

      # Open modal - button is inside the expanded panel footer
      view
      |> element("#mobile-condensed-panel [phx-click=\"toggle_settings_modal\"]")
      |> render_click()

      # Default tab: should show settings content within the modal
      modal = element(view, "#settings-modal") |> render()
      assert modal =~ "Game Settings"
      assert modal =~ "Game Visibility"
      # Switch to provider tab
      view
      |> element(
        "#settings-modal [phx-click=\"select_settings_tab\"][phx-value-tab=\"provider\"]"
      )
      |> render_click()

      modal = element(view, "#settings-modal") |> render()
      assert modal =~ "AI Provider"
      # Switch to events tab
      view
      |> element("#settings-modal [phx-click=\"select_settings_tab\"][phx-value-tab=\"events\"]")
      |> render_click()

      modal = element(view, "#settings-modal") |> render()
      assert modal =~ "Recent Events"
      # Switch back to settings
      view
      |> element(
        "#settings-modal [phx-click=\"select_settings_tab\"][phx-value-tab=\"settings\"]"
      )
      |> render_click()

      modal = element(view, "#settings-modal") |> render()
      assert modal =~ "Game Visibility"
    end

    test "can toggle game visibility through settings modal", %{conn: conn, user: user} do
      # Create a game that's not public
      game = game_fixture(%{is_public: false}, user)
      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")

      # 1. Expand the mobile panel
      view
      |> element(
        "#mobile-condensed-panel [aria-expanded='false'][phx-click='toggle_panel_expansion']"
      )
      |> render_click()

      # 2. Open the settings modal
      view
      |> element("#mobile-condensed-panel [phx-click='toggle_settings_modal']")
      |> render_click()

      # 3. Verify the game is not public initially
      modal = element(view, "#settings-modal") |> render()
      assert modal =~ "Game Visibility"

      # Get the checkbox element
      checkbox = element(view, "input#game-visibility")
      # Should not be checked initially
      refute checkbox |> render() =~ "checked"

      # 4. Toggle the visibility checkbox
      checkbox |> render_click()

      # 5. Verify game visibility was toggled in the database
      updated_game = Games.get_game!(game.id)
      assert updated_game.is_public == true

      # 6. Verify checkbox state updated in the view
      updated_checkbox = element(view, "input#game-visibility")
      assert updated_checkbox |> render() =~ "checked"
    end
  end
end
