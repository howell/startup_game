defmodule StartupGameWeb.GameLive.PlayLiveActingTest do
  alias StartupGame.StreamingService
  use StartupGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import StartupGame.Test.Helpers.Streaming
  alias StartupGame.StreamingService

  alias StartupGame.Games

  defp submit_response(view, response) do
    view
    |> form("form[phx-submit='submit_response']", %{response: response})
    |> render_submit()
  end

  defp create_game(view, name \\ "Acme Inc.", description \\ "A company that makes widgets") do
    submit_response(view, name)
    submit_response(view, description)
  end

  defp select_acting_mode(view) do
    view
    |> element("input[phx-click='set_initial_mode'][phx-value-mode='acting']")
    |> render_click()
  end

  defp get_game_id_from_path(path), do: Path.basename(path)

  describe "Create a game in acting mode" do
    setup :register_and_log_in_user

    test "creates a game in acting mode by selecting 'Start by taking initiative'", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/play")

      # Initial state should be name input
      assert render(view) =~ "What would you like to call your company?"

      # Select "Start by taking initiative" mode
      select_acting_mode(view)

      create_game(view)

      # Should redirect to the game page
      path = assert_patch(view)
      assert path =~ ~r|games/play/.*|

      # Extract game ID from path
      game_id = get_game_id_from_path(path)

      # Verify the game was created in acting mode
      game = Games.get_game!(game_id)
      assert game.current_player_mode == :acting

      # Should not receive a scenario
      refute_receive %{event: "llm_complete"}, 200
    end

    test "submit a response in acting mode", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/play")

      # Select acting mode
      select_acting_mode(view)

      # Submit company name
      create_game(view)
      path = assert_patch(view)
      game_id = get_game_id_from_path(path)
      StreamingService.subscribe(game_id)

      rendered = submit_response(view, "Find an investor")

      assert rendered =~ "Find an investor"

      assert_stream_complete({:ok, outcome})
      Process.sleep(20)
      assert render(view) =~ outcome.text
    end
  end
end
