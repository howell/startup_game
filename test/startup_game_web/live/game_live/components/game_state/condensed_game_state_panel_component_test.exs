defmodule StartupGameWeb.GameLive.Components.GameState.CondensedGameStatePanelComponentTest do
  use StartupGameWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias StartupGameWeb.GameLive.Components.GameState.CondensedGameStatePanel
  alias StartupGame.Games.{Game, Ownership}

  describe "rendering" do
    test "renders collapsed state properly" do
      assigns = %{
        id: "test-panel",
        game: %Game{
          name: "Test Startup",
          cash_on_hand: Decimal.new("100500"),
          burn_rate: Decimal.new("5500"),
          description: "A test startup company"
        },
        ownerships: [
          %Ownership{entity_name: "Founder", percentage: Decimal.new("0.88")},
          %Ownership{entity_name: "Angel", percentage: Decimal.new("0.12")}
        ],
        rounds: [],
        is_expanded: false
      }

      html = render_component(&CondensedGameStatePanel.condensed_game_state_panel/1, assigns)

      assert html =~ "Test Startup"
      assert html =~ "runway"
      assert html =~ "You:"
      assert html =~ "Inv:"
      assert html =~ "hero-chevron-down-mini"
      refute html =~ "FINANCES"
    end

    test "renders expanded state properly" do
      assigns = %{
        id: "test-panel",
        game: %Game{
          name: "Test Startup",
          cash_on_hand: Decimal.new("100500"),
          burn_rate: Decimal.new("5500"),
          description: "A test startup company"
        },
        ownerships: [
          %Ownership{entity_name: "Founder", percentage: Decimal.new("0.88")},
          %Ownership{entity_name: "Angel", percentage: Decimal.new("0.12")}
        ],
        rounds: [],
        is_expanded: true
      }

      html = render_component(&CondensedGameStatePanel.condensed_game_state_panel/1, assigns)

      assert html =~ "Test Startup"
      assert html =~ "FINANCES"
      assert html =~ "Cash"
      assert html =~ "Monthly Burn"
      assert html =~ "Runway"
      assert html =~ "OWNERSHIP"
      assert html =~ "Founder"
      assert html =~ "Angel"
      assert html =~ "Settings"
      assert html =~ "hero-chevron-up-mini"
      # Metrics section has been removed
      refute html =~ "METRICS"
      refute html =~ "Users"
      refute html =~ "MRR"
    end
  end

  describe "helper functions" do
    test "format_ownership_percentage/1 formats percentage correctly" do
      assert CondensedGameStatePanel.format_ownership_percentage(Decimal.new("0.88")) ==
               "88.0%"

      assert CondensedGameStatePanel.format_ownership_percentage(Decimal.new("0.125")) ==
               "12.5%"

      assert CondensedGameStatePanel.format_ownership_percentage(Decimal.new("1.0")) ==
               "100.0%"

      assert CondensedGameStatePanel.format_ownership_percentage(0.88) == "88.0%"
    end

    test "get_founder_percentage/1 returns founder percentage" do
      ownerships = [
        %Ownership{entity_name: "Founder", percentage: Decimal.new("0.88")},
        %Ownership{entity_name: "Angel", percentage: Decimal.new("0.12")}
      ]

      assert Decimal.equal?(
               CondensedGameStatePanel.get_founder_percentage(ownerships),
               Decimal.new("0.88")
             )
    end

    test "get_investor_percentage/1 returns combined investor percentage" do
      ownerships = [
        %Ownership{entity_name: "Founder", percentage: Decimal.new("0.88")},
        %Ownership{entity_name: "Angel", percentage: Decimal.new("0.07")},
        %Ownership{entity_name: "Venture", percentage: Decimal.new("0.05")}
      ]

      assert Decimal.equal?(
               CondensedGameStatePanel.get_investor_percentage(ownerships),
               Decimal.new("0.12")
             )
    end
  end
end
