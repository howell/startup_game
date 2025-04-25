defmodule StartupGameWeb.GameLive.Play.RecoveryTest do
  use StartupGameWeb.ConnCase

  import Phoenix.LiveViewTest
  import StartupGame.GamesFixtures
  import StartupGame.Test.Helpers.Streaming

  alias StartupGame.Games
  alias StartupGame.StreamingService

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
end
