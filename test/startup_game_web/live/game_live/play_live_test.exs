defmodule StartupGameWeb.GameLive.PlayLiveTest do
  use StartupGameWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import StartupGame.GamesFixtures

  alias StartupGame.Games

  describe "Play LiveView - mount" do
    setup :register_and_log_in_user

    test "renders game information when game exists", %{conn: conn, user: user} do
      game = game_fixture(%{name: "Test Game", description: "Test Description"}, user)

      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      assert html =~ "Test Game"
      assert html =~ "Test Description"
      assert html =~ "Cash on Hand"
      assert html =~ "Monthly Burn Rate"
      assert html =~ "Runway"
      assert html =~ "Ownership Structure"
    end

    test "redirects to games index when game doesn't exist", %{conn: conn} do
      non_existent_id = "00000000-0000-0000-0000-000000000000"

      assert {:error, {:redirect, %{to: "/games", flash: %{"error" => "Game not found"}}}} =
               live(conn, ~p"/games/play/#{non_existent_id}")
    end
  end

  describe "Play LiveView - game creation" do
    setup :register_and_log_in_user

    test "submitting a company name transitions to description input", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/play")

      # Initial state should be name input
      assert render(view) =~ "What would you like to name your company?"
      refute render(view) =~ "Please provide a brief description"

      # Submit a company name
      view
      |> form("form[phx-submit='submit_response']", %{response: "Test Company"})
      |> render_submit()

      # Should transition to description input
      assert render(view) =~ "Please provide a brief description of what Test Company does"
      assert render(view) =~ "Test Company"
    end

    test "submitting a company description creates a new game", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/play")

      # Submit company name
      view
      |> form("form[phx-submit='submit_response']", %{response: "Test Company"})
      |> render_submit()

      # Submit company description
      rendered =
        view
        |> form("form[phx-submit='submit_response']", %{response: "A test company description"})
        |> render_submit()

      path = assert_patch(view)
      assert path =~ ~r|games/play/.*|
      # Should create a game and show success message
      assert rendered =~ "Started new venture: Test Company"
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
      rounds = Games.list_game_rounds(game.id)

      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      # Check that all rounds are displayed
      for round <- rounds do
        assert html =~ round.situation

        if round.response do
          assert html =~ round.response
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
      assert html =~ "$50000.00"
      # Burn rate
      assert html =~ "$5000.00"
      # Runway (50000/5000 = 10)
      assert html =~ "10.0"
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

      {:ok, _view, html} = live(conn, ~p"/games/play/#{game.id}")

      assert html =~ "How do you want to respond?"
      assert html =~ "Send Response"
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
      assert html =~ "Congratulations! Your company was acquired for $2000000.00"
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
      assert html =~ "Congratulations! Your company went public with a valuation of $5000000.00"
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
      assert length(Games.list_game_rounds(game.id)) == 1

      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")

      view
      |> form("form[phx-submit='submit_response']", %{response: "accept"})
      |> render_submit()

      updated_rounds = Games.list_game_rounds(game.id)
      assert [first_round, _second_round] = updated_rounds

      assert first_round.response == "accept"
    end

    test "submitting an empty response does nothing", %{conn: conn, user: user} do
      game = game_fixture(%{start?: true}, user)
      initial_rounds_count = length(Games.list_game_rounds(game.id))

      {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")

      # Submit an empty response
      view
      |> form("form[phx-submit='submit_response']", %{response: ""})
      |> render_submit()

      # Check that no new round was created
      updated_rounds = Games.list_game_rounds(game.id)
      assert length(updated_rounds) == initial_rounds_count
    end

    # Commenting out this test as it requires the meck dependency
    # To enable it, add {:meck, "~> 0.9.2", only: :test} to deps in mix.exs
    #
    # test "handles error when processing response", %{conn: conn, user: user} do
    #   # Create a game with a mock provider that will cause an error
    #   game = game_fixture(%{}, user)
    #
    #   # Mock the GameService.process_response to return an error
    #   expect_error_message = "Test error message"
    #
    #   # Use meck to mock the GameService module
    #   :ok = :meck.new(StartupGame.GameService, [:passthrough])
    #   :ok = :meck.expect(StartupGame.GameService, :process_response, fn _id, _response ->
    #     {:error, expect_error_message}
    #   end)
    #
    #   {:ok, view, _html} = live(conn, ~p"/games/play/#{game.id}")
    #
    #   # Submit a response
    #   rendered = view
    #   |> form("form[phx-submit='submit_response']", %{response: "This should cause an error"})
    #   |> render_submit()
    #
    #   # Check for error flash
    #   assert rendered =~ "Error processing response: #{inspect(expect_error_message)}"
    #
    #   # Clean up the mock
    #   :meck.unload(StartupGame.GameService)
    # end
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
      assert html =~ "$12345.67"
      # Burn rate
      assert html =~ "$1234.56"
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
      assert html =~ "3.0"
    end
  end
end
