defmodule StartupGameWeb.GameLive.Components.GameState.CondensedGameStatePanelComponentTest do
  use StartupGameWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component, except: [assign: 3]

  alias StartupGameWeb.GameLive.Components.GameState.CondensedGameStatePanel
  alias StartupGame.Games.{Game, Ownership}

  describe "rendering" do
    test "renders collapsed state properly" do
      game = %Game{
        name: "Test Startup",
        cash_on_hand: Decimal.new("100500"),
        burn_rate: Decimal.new("5500"),
        description: "A test startup company"
      }

      ownerships = [
        %Ownership{entity_name: "Founder", percentage: Decimal.new(88)},
        %Ownership{entity_name: "Angel", percentage: Decimal.new(12)}
      ]

      assigns = %{
        game: game,
        ownerships: ownerships,
        rounds: [],
        is_expanded: false
      }

      html =
        rendered_to_string(~H"""
        <CondensedGameStatePanel.condensed_game_state_panel
          id="test-panel"
          game={@game}
          ownerships={@ownerships}
          rounds={@rounds}
          is_expanded={@is_expanded}
        />
        """)

      assert html =~ "chevron-down"
      assert html =~ "$100.5k"
      assert html =~ "$5.5k"
      assert html =~ "88.0%"
      refute html =~ "FINANCES"
    end

    test "renders expanded state properly" do
      game = %Game{
        name: "Test Startup",
        cash_on_hand: Decimal.new("100500"),
        burn_rate: Decimal.new("5500"),
        description: "A test startup company"
      }

      ownerships = [
        %Ownership{entity_name: "Founder", percentage: Decimal.new(88)},
        %Ownership{entity_name: "Angel", percentage: Decimal.new(12)}
      ]

      assigns = %{
        game: game,
        ownerships: ownerships,
        rounds: [],
        is_expanded: true
      }

      # Test expanded panel without custom footer
      expanded_html =
        rendered_to_string(~H"""
        <CondensedGameStatePanel.condensed_game_state_panel
          id="test-panel"
          game={@game}
          ownerships={@ownerships}
          rounds={@rounds}
          is_expanded={@is_expanded}
        />
        """)

      assert expanded_html =~ "Test Startup"
      assert expanded_html =~ "FINANCES"
      assert expanded_html =~ "Cash"
      assert expanded_html =~ "Monthly Burn"
      assert expanded_html =~ "Runway"
      assert expanded_html =~ "OWNERSHIP"
      assert expanded_html =~ "Founder"
      assert expanded_html =~ "Angel"
      assert expanded_html =~ "chevron-up"
      # Metrics section has been removed
      refute expanded_html =~ "METRICS"
      refute expanded_html =~ "Users"
      refute expanded_html =~ "MRR"
    end

    test "renders with custom expanded footer" do
      game = %Game{
        name: "Test Startup",
        cash_on_hand: Decimal.new("100500"),
        burn_rate: Decimal.new("5500"),
        description: "A test startup company"
      }

      ownerships = [
        %Ownership{entity_name: "Founder", percentage: Decimal.new(88)},
        %Ownership{entity_name: "Angel", percentage: Decimal.new(12)}
      ]

      assigns = %{
        game: game,
        ownerships: ownerships,
        rounds: [],
        is_expanded: true
      }

      html =
        rendered_to_string(~H"""
        <CondensedGameStatePanel.condensed_game_state_panel
          id="test-panel"
          game={@game}
          ownerships={@ownerships}
          rounds={@rounds}
          is_expanded={@is_expanded}
        >
          <:expanded_footer>
            <div class="custom-footer">Custom Footer Content</div>
          </:expanded_footer>
        </CondensedGameStatePanel.condensed_game_state_panel>
        """)

      assert html =~ "Test Startup"
      assert html =~ "FINANCES"
      assert html =~ "custom-footer"
      assert html =~ "Custom Footer Content"
      refute html =~ "Settings"
    end

    test "triggers settings modal when settings button clicked" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <CondensedGameStatePanel.panel_footer />
        """)

      assert html =~ "Settings"
      assert html =~ "phx-click=\"toggle_settings_modal\""
    end

    test "handles expand/collapse event" do
      game = %Game{
        name: "Test Startup",
        cash_on_hand: Decimal.new("100500"),
        burn_rate: Decimal.new("5500"),
        description: "A test startup company"
      }

      ownerships = [
        %Ownership{entity_name: "Founder", percentage: Decimal.new(88)},
        %Ownership{entity_name: "Angel", percentage: Decimal.new(12)}
      ]

      assigns = %{
        game: game,
        ownerships: ownerships,
        rounds: [],
        is_expanded: false
      }

      html =
        rendered_to_string(~H"""
        <CondensedGameStatePanel.condensed_game_state_panel
          id="test-panel"
          game={@game}
          ownerships={@ownerships}
          rounds={@rounds}
          is_expanded={@is_expanded}
        />
        """)

      # The expand button should be present
      assert html =~ "phx-click=\"toggle_panel_expansion\""
    end
  end

  describe "helper functions" do
    test "get_founder_percentage/1 returns founder percentage" do
      ownerships = [
        %Ownership{entity_name: "Founder", percentage: Decimal.new(88)},
        %Ownership{entity_name: "Angel", percentage: Decimal.new(12)}
      ]

      assert Decimal.equal?(
               CondensedGameStatePanel.get_founder_percentage(ownerships),
               Decimal.new(88)
             )
    end

    test "get_investor_percentage/1 returns combined investor percentage" do
      ownerships = [
        %Ownership{entity_name: "Founder", percentage: Decimal.new(88)},
        %Ownership{entity_name: "Angel", percentage: Decimal.new(7)},
        %Ownership{entity_name: "Venture", percentage: Decimal.new(5)}
      ]

      assert Decimal.equal?(
               CondensedGameStatePanel.get_investor_percentage(ownerships),
               Decimal.new(12)
             )
    end
  end
end
