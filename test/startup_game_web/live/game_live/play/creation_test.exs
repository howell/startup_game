defmodule StartupGameWeb.GameLive.Play.CreationTest do
  use StartupGameWeb.ConnCase

  import Phoenix.LiveViewTest

  alias StartupGameWeb.GameLive.Play.PlayTestHelpers

  describe "Play LiveView - game creation" do
    setup :register_and_log_in_user

    test "submitting a company name transitions to description input", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/play")

      # Initial state should be name input
      assert render(view) =~ "What would you like to call your company?"
      refute render(view) =~ "Provide a brief description"

      # Submit a company name
      PlayTestHelpers.submit_response(view, "Test Company")

      # Should transition to description input
      assert render(view) =~
               "Now, tell us what Test Company does. Provide a brief description of your startup"
    end

    test "submitting a company description creates a new game", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/play")

      # Submit company name
      PlayTestHelpers.submit_response(view, "Test Company")

      # Submit company description
      rendered = PlayTestHelpers.submit_response(view, "A test company description")

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
end
