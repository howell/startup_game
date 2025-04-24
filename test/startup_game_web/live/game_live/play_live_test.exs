defmodule StartupGameWeb.GameLive.PlayLiveTest do
  use StartupGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import StartupGame.GamesFixtures
  import StartupGame.Test.Helpers.Streaming
  import StartupGame.AccountsFixtures

  alias StartupGame.Games
  alias StartupGame.StreamingService

  defp submit_response(view, response) do
    view
    |> form("form[phx-submit='submit_response']", %{response: response})
    |> render_submit()
  end

  describe "Play LiveView - mount" do
    setup :register_and_log_in_user

    test "renders game information when game exists", %{conn: conn, user: user} do
      game = game_fixture(%{name: "Test Game", description: "Test Description"}, user)

      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      assert html =~ "Test Game"
      assert html =~ "Test Description"
      assert html =~ "Cash"
      assert html =~ "Burn Rate"
      assert html =~ "Runway"
      assert html =~ "OWNERSHIP STRUCTURE"
    end

    test "redirects to games index when game doesn't exist", %{conn: conn} do
      non_existent_id = "00000000-0000-0000-0000-000000000000"

      assert {:error, {:redirect, %{to: "/games"}}} =
               live(conn, ~p"/games/play/#{non_existent_id}")
    end
  end

  describe "Play LiveView - game creation" do
    setup :register_and_log_in_user

    test "submitting a company name transitions to description input", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/play")

      # Initial state should be name input
      assert render(view) =~ "What would you like to call your company?"
      refute render(view) =~ "Provide a brief description"

      # Submit a company name
      submit_response(view, "Test Company")

      # Should transition to description input
      assert render(view) =~
               "Now, tell us what Test Company does. Provide a brief description of your startup"
    end

    test "submitting a company description creates a new game", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/play")

      # Submit company name
      submit_response(view, "Test Company")

      # Submit company description
      rendered = submit_response(view, "A test company description")

      path = assert_patch(view)
      assert path =~ ~r|games/play/.*|
      # Should create a game and show success message
      assert rendered =~ "Test Company"
    end

    test "can set provider preference during game creation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/play")

      # Check that provider selector is shown
      assert render(view) =~ "Scenario Provider"

      # Change the provider
      view
      |> form("form[phx-submit='set_provider']", %{
        provider: "Elixir.StartupGame.Engine.Demo.StaticScenarioProvider"
      })
      |> render_submit()

      # Should show confirmation message
      assert render(view) =~
               "Scenario provider set to Elixir.StartupGame.Engine.Demo.StaticScenarioProvider"
    end
  end

  describe "Play LiveView - game display" do
    setup :register_and_log_in_user

    test "displays rounds and messages correctly", %{conn: conn, user: user} do
      game = complete_game_fixture(%{}, user)
      Games.update_game(game, %{status: :failed})
      rounds = Games.list_game_rounds(game.id)

      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      # Check that all rounds are displayed
      for round <- rounds do
        assert html =~ round.situation

        if round.player_input do
          assert html =~ round.player_input
        end

        if round.outcome do
          assert html =~ round.outcome
        end
      end
    end

    test "displays financial information correctly", %{conn: conn, user: user} do
      game =
        game_fixture(
          %{
            cash_on_hand: Decimal.new("50000.00"),
            burn_rate: Decimal.new("5000.00")
          },
          user
        )

      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      # Cash on hand
      assert html =~ "$50.0k"
      # Burn rate
      assert html =~ "$5.0k"
      # Runway (50000/5000 = 10)
      assert html =~ "10"
    end

    test "displays ownership structure correctly", %{conn: conn, user: user} do
      game = game_fixture(%{}, user)
      ownership_fixture(game, %{entity_name: "Founder", percentage: Decimal.new("70.0")})
      ownership_fixture(game, %{entity_name: "Investor", percentage: Decimal.new("30.0")})

      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      assert html =~ "Founder"
      assert html =~ "70.0%"
      assert html =~ "Investor"
      assert html =~ "30.0%"
    end
  end

  describe "Play LiveView - game status" do
    setup :register_and_log_in_user

    test "shows input form for in-progress games", %{conn: conn, user: user} do
      game = game_fixture(%{status: :in_progress}, user)
      Games.create_round(%{game_id: game.id, situation: "Test situation"})

      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      assert html =~ "Respond to the situation"
      assert html =~ "hero-paper-airplane"
    end

    test "shows acquisition end screen", %{conn: conn, user: user} do
      game =
        game_fixture_with_status(
          :completed,
          %{
            exit_type: :acquisition,
            exit_value: Decimal.new("2000000.00")
          },
          user
        )

      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      assert html =~ "Game Acquired!"
      assert html =~ "Congratulations! Your company was acquired for $2.0M"
      assert html =~ "Back to Games"
      # Input form should not be shown
      refute html =~ "How do you want to respond?"
    end

    test "shows IPO end screen", %{conn: conn, user: user} do
      game =
        game_fixture_with_status(
          :completed,
          %{
            exit_type: :ipo,
            exit_value: Decimal.new("5000000.00")
          },
          user
        )

      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      assert html =~ "Game IPO Successful!"
      assert html =~ "Congratulations! Your company went public with a valuation of $5.0M"
      assert html =~ "Back to Games"
    end

    test "shows failure end screen", %{conn: conn, user: user} do
      game = game_fixture_with_status(:failed, %{exit_type: :shutdown}, user)

      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      assert html =~ "Game Failed"
      assert html =~ "Unfortunately, your startup ran out of money and had to shut down"
      assert html =~ "Back to Games"
    end
  end

  describe "Play LiveView - response submission" do
    setup :register_and_log_in_user

    test "submitting a response creates a new round", %{conn: conn, user: user} do
      game = game_fixture(%{start?: true}, user)

      Games.create_round(%{
        game_id: game.id,
        situation: "An angel investor offers $100,000 for 15% of your company."
      })

      assert length(Games.list_game_rounds(game.id)) == 1

      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")

      StreamingService.subscribe(game.id)

      submit_response(view, "accept")

      assert_stream_complete()
      html = render(view)
      assert html =~ "accept"

      updated_rounds = Games.list_game_rounds(game.id)
      assert length(updated_rounds) >= 1
      first_round = List.first(updated_rounds)
      assert first_round.player_input == "accept"

      assert_stream_complete()

      Process.sleep(20)

      updated_rounds = Games.list_game_rounds(game.id)
      assert length(updated_rounds) >= 2
    end

    test "outcome is finalized before next scenario starts streaming", %{conn: conn, user: user} do
      # Start the mock streaming adapter
      {:ok, _pid} = StartupGame.Mocks.LLM.MockStreamingAdapter.start_link()

      # Create a game with a provider that will use our mock adapter
      game = game_fixture(%{}, user)

      StreamingService.subscribe(game.id)
      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")

      assert_stream_complete({:ok, _scenario}, _, 500)

      # Get the initial situation
      initial_html = render(view)
      # From StaticScenarioProvider
      assert initial_html =~ "An angel investor offers $100,000 for 15% of your company."

      # Submit a response
      response_text = "accept"

      submit_response(view, response_text)

      assert render(view) =~ response_text

      # Then outcome completion
      assert_stream_complete({:ok, outcome}, stream_id)

      Process.sleep(20)

      # CRITICAL TEST: After outcome completion, the outcome should be visible in the UI as a message
      html_after_outcome = render(view)
      # User's response should be visible
      assert html_after_outcome =~ response_text

      # The outcome text should be in the database and visible in the UI
      assert outcome.text
      # From MockStreamingAdapter
      assert html_after_outcome =~ "You accept the offer and receive the investment"

      # Finally scenario completion
      assert_stream_complete({:ok, _scenario}, new_stream_id)

      # Should be a different stream ID
      refute new_stream_id == stream_id

      # Final verification: both outcome and new scenario should be visible
      final_html = render(view)
      assert final_html =~ response_text
      # New scenario text
      assert final_html =~ "You need to hire a key employee."
    end

    test "submitting an empty response does nothing", %{conn: conn, user: user} do
      game = game_fixture(%{start?: true, player_mode: :acting}, user)
      initial_rounds_count = length(Games.list_game_rounds(game.id))

      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")

      # Submit an empty response
      submit_response(view, "")

      # Check that no new round was created
      updated_rounds = Games.list_game_rounds(game.id)
      assert length(updated_rounds) == initial_rounds_count
    end
  end

  describe "Play LiveView - helper functions" do
    setup :register_and_log_in_user

    test "format_money formats decimal values correctly", %{conn: conn, user: user} do
      game =
        game_fixture(
          %{
            cash_on_hand: Decimal.new("12345.67"),
            burn_rate: Decimal.new("1234.56"),
            start?: false
          },
          user
        )

      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      # Cash on hand
      assert html =~ "$12.3k"
      # Burn rate
      assert html =~ "$1.2k"
    end

    test "format_percentage formats decimal values correctly", %{conn: conn, user: user} do
      game = game_fixture(%{}, user)
      ownership_fixture(game, %{entity_name: "Test Entity", percentage: Decimal.new("12.34")})

      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      # Percentage with one decimal place
      assert html =~ "12.3%"
    end

    test "format_runway formats decimal values correctly", %{conn: conn, user: user} do
      game =
        game_fixture(
          %{
            cash_on_hand: Decimal.new("10000.00"),
            burn_rate: Decimal.new("3333.33")
          },
          user
        )

      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      # Runway (10000/3333.33 ≈ 3.0)
      assert html =~ "3"
    end
  end

  describe "Play LiveView - game state recovery" do
    setup :register_and_log_in_user

    test "starts async recovery when round has response but no outcome", %{conn: conn, user: user} do
      # Create a game with a round that has a response but no outcome
      game = game_fixture(%{player_mode: :responding}, user)

      Games.create_round(%{
        game_id: game.id,
        situation: "An angel investor offers $100,000 for 15% of your company.",
        player_input: "accept",
        outcome: nil
      })

      # Connect to the LiveView
      StreamingService.subscribe(game.id)
      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")

      # Verify recovery message is shown
      assert render(view) =~ "Resuming game"

      assert_stream_complete({:ok, _})

      assert render(view) =~ "You accept the offer and receive the investment"
    end

    test "generates initial scenario if not present and player is responding", %{
      conn: conn,
      user: user
    } do
      # Create a game with all rounds complete but no current scenario
      game = game_fixture(%{player_mode: :responding}, user)

      StreamingService.subscribe(game.id)
      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")

      assert_stream_complete({:ok, _})
      # Verify recovery happened
      assert render(view) =~ "An angel investor offers $100,000 for 15% of your company."
    end

    test "generates next scenario when all rounds complete and player is responding", %{
      conn: conn,
      user: user
    } do
      # Create a game with all rounds complete but no current scenario
      game = game_fixture(%{player_mode: :responding}, user)

      Games.create_round(%{
        game_id: game.id,
        situation: "An angel investor offers $100,000 for 15% of your company.",
        player_input: "accept",
        outcome: "outcome"
      })

      StreamingService.subscribe(game.id)
      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")

      assert_stream_complete({:ok, _})
      # Verify recovery happened
      assert render(view) =~ "You need to hire a key employee."
    end
  end

  describe "Play LiveView - play static game from start to finish" do
    setup :register_and_log_in_user

    test "play static game from start to finish", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/play")

      # 1. Set provider to Static
      view
      |> form("form[phx-submit='set_provider']", %{
        provider: "Elixir.StartupGame.Engine.Demo.StaticScenarioProvider"
      })
      |> render_submit()

      assert render(view) =~
               "Scenario provider set to Elixir.StartupGame.Engine.Demo.StaticScenarioProvider"

      # 2. Submit Name
      submit_response(view, "Static Test Co")
      assert render(view) =~ "Now, tell us what Static Test Co does."

      # 3. Submit Description (starts the game)
      submit_response(view, "A company for static testing.")
      path = assert_patch(view)
      assert path =~ ~r|games/play/.*|
      assert render(view) =~ "Static Test Co"
      game_id = Path.basename(path)
      StreamingService.subscribe(game_id)

      # --- Scenario 1: Angel Investment ---
      # Wait for initial scenario; hard to guarantee that we will subscribe to the game ID in time to get the message
      Process.sleep(100)
      assert render(view) =~ "An angel investor offers $100,000 for 15% of your company."
      # Submit response
      submit_response(view, "accept")
      assert render(view) =~ "accept"
      # Wait for outcome
      assert_stream_complete({:ok, _outcome})
      assert render(view) =~ "You accept the offer and receive the investment."
      chat_history = element(view, "#chat-history") |> render()
      # check for round state changes
      assert chat_history =~ ~r/Cash:.+\+100\.0k/
      assert chat_history =~ "Angel Investor:"
      assert chat_history =~ "15.0%"

      # --- Scenario 2: Hiring Decision ---
      # Wait for next scenario
      assert_stream_complete({:ok, _scenario})
      assert render(view) =~ "You need to hire a key employee."
      # Submit response
      submit_response(view, "experienced")
      assert render(view) =~ "experienced"
      # Wait for outcome
      assert_stream_complete({:ok, _outcome})
      assert render(view) =~ "The experienced developer brings immediate value"

      # --- Scenario 3: Lawsuit ---
      # Wait for next scenario
      assert_stream_complete({:ok, _scenario})
      assert render(view) =~ "Your startup has been sued by a competitor"
      # Submit response
      submit_response(view, "settle")
      assert render(view) =~ "settle"
      # Wait for outcome
      assert_stream_complete({:ok, _outcome})
      assert render(view) =~ "You settle the lawsuit for $50,000"

      # --- Scenario 4: Acquisition Offer ---
      # Wait for next scenario
      assert_stream_complete({:ok, _scenario})
      assert render(view) =~ "A larger company offers to acquire your startup for $2 million."
      # Submit response (Accept acquisition)
      submit_response(view, "counter")
      assert render(view) =~ "counter"
      # Wait for outcome (which ends the game)
      assert_stream_complete({:ok, outcome})
      assert outcome.exit_type == :acquisition

      # 5. Check End State
      html = render(view)
      assert html =~ "Game Acquired!"
      assert html =~ "Congratulations! Your company was acquired for $2.5M"
      # Input form should be gone
      refute html =~ "Respond to the situation"
      # should not receive another scenario
      refute_receive(%{event: "llm_complete"})
    end
  end

  describe "Play LiveView - round state changes" do
    setup :register_and_log_in_user

    test "displays round state changes correctly", %{conn: conn, user: user} do
      # Create game with start? as false to prevent scenario generation
      game = game_fixture(%{start?: false, player_mode: :acting}, user)

      # Create a round with cash changes
      _round1 =
        Games.create_round(%{
          game_id: game.id,
          situation: "Investment received",
          player_input: "accept investment",
          outcome: "You received the investment",
          cash_change: Decimal.new("100000.00"),
          burn_rate_change: Decimal.new("5000.00")
        })

      # Create a round with ownership changes
      _round2 =
        Games.create_round(%{
          game_id: game.id,
          situation: "Investor proposal",
          player_input: "accept proposal",
          outcome: "Investor joins the board"
        })

      # Create ownership records for the game first (so they exist)
      ownership_fixture(game, %{entity_name: "Founder", percentage: Decimal.new("90.0")})
      ownership_fixture(game, %{entity_name: "Investor", percentage: Decimal.new("10.0")})

      # Now create the ownership changes for that round
      [_round1, round2] = Games.list_game_rounds(game.id)

      Games.create_ownership_change(%{
        entity_name: "Founder",
        percentage_delta: Decimal.new("-10.00"),
        change_type: :dilution,
        game_id: game.id,
        round_id: round2.id
      })

      Games.create_ownership_change(%{
        entity_name: "Investor",
        percentage_delta: Decimal.new("10.00"),
        change_type: :investment,
        game_id: game.id,
        round_id: round2.id
      })

      # Create a round with no changes
      _round3 =
        Games.create_round(%{
          game_id: game.id,
          situation: "New feature request",
          player_input: "work on feature",
          outcome: "Feature completed successfully"
        })

      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")

      html = element(view, "#chat-history") |> render()
      # Check that cash changes are displayed correctly
      assert html =~ ~r/Cash:.+100\.0k/
      assert html =~ ~r/Burn Rate:.+5\.0k/

      # Check that ownership changes are displayed correctly
      # Look for less specific patterns that are likely in the HTML
      assert html =~ "Founder"
      assert html =~ "-10.0%"
      assert html =~ "Investor"
      assert html =~ "+10.0%"

      # Verify icons are present
      assert html =~ "hero-currency-dollar"
      assert html =~ "hero-fire"
      assert html =~ "hero-user-plus"
      assert html =~ "hero-arrow-trending-down"
      assert html =~ "hero-arrow-trending-up"
    end

    test "does not display state changes section when no changes", %{conn: conn, user: user} do
      game = game_fixture(%{start?: false, player_mode: :acting}, user)

      # Create a round with no changes
      Games.create_round(%{
        game_id: game.id,
        situation: "New feature request",
        player_input: "work on feature",
        outcome: "Feature completed successfully"
      })

      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      # The specific change indicators shouldn't be present
      refute html =~ "Cash:"
      refute html =~ "Burn Rate:"

      # The state changes div should not appear with its class
      refute html =~ ~r/class=.*flex flex-col md:flex-row md:items-center gap-4.*/
    end
  end

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
  end

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
  end
end
