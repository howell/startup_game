defmodule StartupGameWeb.GameLive.Play.ActingModeTest do
  use StartupGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import StartupGame.GamesFixtures
  import StartupGame.Test.Helpers.Streaming

  alias StartupGame.Games
  alias StartupGame.StreamingService
  alias StartupGameWeb.GameLive.Play.PlayTestHelpers

  describe "Play LiveView - creating game in acting mode" do
    setup :register_and_log_in_user

    test "creates a game in acting mode by selecting 'Start by taking initiative'", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/play")

      # Initial state should be name input
      assert render(view) =~ "What would you like to call your company?"

      # Select "Start by taking initiative" mode
      PlayTestHelpers.select_acting_mode(view)

      PlayTestHelpers.create_game(view)

      # Should redirect to the game page
      path = assert_patch(view)
      assert path =~ ~r|games/play/.*|

      # Extract game ID from path
      game_id = PlayTestHelpers.get_game_id_from_path(path)

      # Verify the game was created in acting mode
      game = Games.get_game!(game_id)
      assert game.current_player_mode == :acting

      # Should not receive a scenario
      refute_receive %{event: "llm_complete"}, 200
    end

    test "submit a response in acting mode", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/play")

      # Select acting mode
      PlayTestHelpers.select_acting_mode(view)

      # Submit company name
      PlayTestHelpers.create_game(view)
      path = assert_patch(view)
      game_id = PlayTestHelpers.get_game_id_from_path(path)
      StreamingService.subscribe(game_id)

      rendered = PlayTestHelpers.submit_response(view, "Find an investor")

      assert rendered =~ "Find an investor"

      assert_stream_complete({:ok, outcome})
      Process.sleep(20)
      assert render(view) =~ outcome.text
    end
  end

  describe "Play LiveView - switching player modes" do
    setup :register_and_log_in_user

    test "can switch from responding to acting mode", %{conn: conn, user: user} do
      game = game_fixture(%{player_mode: :responding}, user)

      # Initial round
      Games.create_round(%{
        game_id: game.id,
        situation: "Test situation"
      })

      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")

      # Button to switch mode should be visible and have right text
      assert has_element?(
               view,
               "button[phx-click='switch_player_mode'][phx-value-player_mode='acting']"
             )

      assert render(view) =~ "Take the Wheel!"

      # Click the button to switch to acting mode
      view
      |> element("button[phx-click='switch_player_mode'][phx-value-player_mode='acting']")
      |> render_click()

      # Check that mode switched properly
      updated_game = Games.get_game!(game.id)
      assert updated_game.current_player_mode == :acting

      # Button text should change
      assert has_element?(
               view,
               "button[phx-click='switch_player_mode'][phx-value-player_mode='responding']"
             )

      assert render(view) =~ "Bezos Take the Wheel!"

      # Placeholder text should change
      input_content =
        element(view, "textarea[placeholder*='What action will you take?']") |> render()

      assert input_content =~ "What action will you take?"
    end

    test "can switch from acting to responding mode", %{conn: conn, user: user} do
      game = game_fixture(%{player_mode: :acting}, user)

      # Initial round with a situation
      Games.create_round(%{
        game_id: game.id,
        situation: "Test situation"
      })

      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")

      # Button to switch mode should be visible and have right text
      assert has_element?(
               view,
               "button[phx-click='switch_player_mode'][phx-value-player_mode='responding']"
             )

      assert render(view) =~ "Bezos Take the Wheel!"

      # Click the button to switch to responding mode
      view
      |> element("button[phx-click='switch_player_mode'][phx-value-player_mode='responding']")
      |> render_click()

      # Check that mode switched properly
      updated_game = Games.get_game!(game.id)
      assert updated_game.current_player_mode == :responding

      # Button text should change
      assert has_element?(
               view,
               "button[phx-click='switch_player_mode'][phx-value-player_mode='acting']"
             )

      assert render(view) =~ "Take the Wheel!"

      # Check placeholder text - this doesn't rely on streaming
      # Give the UI a moment to update
      Process.sleep(200)
      assert render(view) =~ "Respond to the situation"
    end
  end
end
