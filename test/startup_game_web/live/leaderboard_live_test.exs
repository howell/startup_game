defmodule StartupGameWeb.LeaderboardLiveTest do
  use StartupGameWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import StartupGame.AccountsFixtures
  import StartupGame.GamesFixtures

  describe "LeaderboardLive" do
    setup do
      # Create test users
      user1 = user_fixture(%{username: "user1", default_game_visibility: :public})
      user2 = user_fixture(%{username: "user2", default_game_visibility: :public})
      user3 = user_fixture(%{username: "user3", default_game_visibility: :public})

      # Create games with different exit values and founder returns
      game_a =
        game_fixture_with_ownership(
          %{
            name: "Company A",
            status: :completed,
            exit_type: :acquisition,
            exit_value: Decimal.new("3000000"),
            percentage: Decimal.new("40.0"),
            founder_return: Decimal.new("1200000")
          },
          user1
        )

      game_b =
        game_fixture_with_ownership(
          %{
            name: "Company B",
            status: :completed,
            exit_type: :acquisition,
            exit_value: Decimal.new("1000000"),
            percentage: Decimal.new("90.0"),
            founder_return: Decimal.new("900000")
          },
          user2
        )

      game_c =
        game_fixture_with_ownership(
          %{
            name: "Company C",
            status: :completed,
            exit_type: :acquisition,
            exit_value: Decimal.new("2000000"),
            percentage: Decimal.new("80.0"),
            founder_return: Decimal.new("1600000")
          },
          user3
        )

      %{games: [game_a, game_b, game_c]}
    end

    test "renders leaderboard with default sorting (exit_value desc)", %{conn: conn} do
      # Verify games are properly set up for leaderboard
      assert length(StartupGame.Games.list_leaderboard_games()) == 3

      {:ok, _view, html} = live(conn, ~p"/leaderboard")

      # Check page title and header
      assert html =~ "Startup Success Leaderboard"

      # Check companies are displayed
      assert html =~ "Company A"
      assert html =~ "Company B"
      assert html =~ "Company C"

      # Check default sorting (exit_value descending)
      companies =
        Floki.find(html, "tr td:nth-child(3) div")
        |> Floki.text(sep: "|")
        |> String.split("|")
        |> Enum.map(&String.trim/1)

      assert companies == ["Company A", "Company C", "Company B"]
    end

    test "can sort by exit_value in ascending order", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/leaderboard")

      # Click on exit value header to sort ascending (toggle from default desc)
      html =
        view
        |> element("th[phx-value-field='exit_value']")
        |> render_click()

      # Check sorting (exit_value ascending)
      companies =
        Floki.find(html, "tr td:nth-child(3) div")
        |> Floki.text(sep: "|")
        |> String.split("|")
        |> Enum.map(&String.trim/1)

      assert companies == ["Company B", "Company C", "Company A"]
    end

    test "can sort by founder_return in descending order", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/leaderboard")

      # Click on founder return header to sort by founder_return
      html =
        view
        |> element("th[phx-value-field='founder_return']")
        |> render_click()

      # Check sorting (founder_return descending)
      companies =
        Floki.find(html, "tr td:nth-child(3) div")
        |> Floki.text(sep: "|")
        |> String.split("|")
        |> Enum.map(&String.trim/1)

      assert companies == ["Company C", "Company A", "Company B"]
    end

    test "can sort by founder_return in ascending order", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/leaderboard")

      # Click on founder return header to sort by founder_return (first click for desc)
      view
      |> element("th[phx-value-field='founder_return']")
      |> render_click()

      # Click again to toggle to ascending order
      html =
        view
        |> element("th[phx-value-field='founder_return']")
        |> render_click()

      # Check sorting (founder_return ascending)
      companies =
        Floki.find(html, "tr td:nth-child(3) div")
        |> Floki.text(sep: "|")
        |> String.split("|")
        |> Enum.map(&String.trim/1)

      assert companies == ["Company B", "Company A", "Company C"]
    end

    test "can toggle between ascending and descending order", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/leaderboard")

      # Default is exit_value descending: A, C, B

      # First click on same column toggles to ascending: B, C, A
      html =
        view
        |> element("th[phx-value-field='exit_value']")
        |> render_click()

      companies =
        Floki.find(html, "tr td:nth-child(3) div")
        |> Floki.text(sep: "|")
        |> String.split("|")
        |> Enum.map(&String.trim/1)

      assert companies == ["Company B", "Company C", "Company A"]

      # Second click on same column toggles back to descending: A, C, B
      html =
        view
        |> element("th[phx-value-field='exit_value']")
        |> render_click()

      companies =
        Floki.find(html, "tr td:nth-child(3) div")
        |> Floki.text(sep: "|")
        |> String.split("|")
        |> Enum.map(&String.trim/1)

      assert companies == ["Company A", "Company C", "Company B"]
    end

    test "clicking different column changes sort field and resets to descending", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/leaderboard")

      # Default is exit_value descending: A, C, B

      # Click on exit_value to change to ascending: B, C, A
      view
      |> element("th[phx-value-field='exit_value']")
      |> render_click()

      # Now click on founder_return - should sort by founder_return descending: C, A, B
      html =
        view
        |> element("th[phx-value-field='founder_return']")
        |> render_click()

      companies =
        Floki.find(html, "tr td:nth-child(3) div")
        |> Floki.text(sep: "|")
        |> String.split("|")
        |> Enum.map(&String.trim/1)

      assert companies == ["Company C", "Company A", "Company B"]
    end

    test "renders the leaderboard with game links", %{conn: conn, games: [game_a, game_b, game_c]} do
      {:ok, view, html} = live(conn, ~p"/leaderboard")

      # Assert that the page title is present
      assert html =~ "Startup Success Leaderboard"

      # Assert that the game's name is rendered
      assert html =~ "Company A"
      assert html =~ "Company B"
      assert html =~ "Company C"

      # Assert that there's a link to the game view page
      assert has_element?(view, "a[href='/games/view/#{game_a.id}']", "Company A")
      assert has_element?(view, "a[href='/games/view/#{game_b.id}']", "Company B")
      assert has_element?(view, "a[href='/games/view/#{game_c.id}']", "Company C")

      c_url = ~p"/games/view/#{game_c.id}"

      # Click the company name link and verify navigation
      assert {:error, {:live_redirect, %{to: ^c_url}}} =
               view |> element("a", "Company C") |> render_click()
    end
  end
end
