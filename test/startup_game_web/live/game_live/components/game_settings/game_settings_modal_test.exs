defmodule StartupGameWeb.GameLive.Components.GameSettings.GameSettingsModalTest do
  use StartupGameWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias StartupGameWeb.GameLive.Components.GameSettings.GameSettingsModal
  alias StartupGame.Games.{Game, Round}

  describe "rendering" do
    test "renders visibility tab by default" do
      assigns = %{
        id: "test-modal",
        game: %Game{
          is_public: true,
          is_leaderboard_eligible: false,
          provider_preference: "StartupGame.Engine.LLMScenarioProvider"
        },
        rounds: [],
        available_providers: [],
        selected_provider: nil,
        is_open: true,
        current_tab: "settings"
      }

      html = render_component(&GameSettingsModal.game_settings_modal/1, assigns)

      assert html =~ "Game Settings"
      assert html =~ "Game Visibility"
      assert html =~ "Make this game public"
      assert html =~ "Public games will be visible"
      refute html =~ "Select which AI provider"
    end

    test "renders provider tab when selected" do
      assigns = %{
        id: "test-modal",
        game: %Game{
          is_public: true,
          is_leaderboard_eligible: false,
          provider_preference: "StartupGame.Engine.LLMScenarioProvider"
        },
        rounds: [],
        available_providers: [
          "Test Provider"
        ],
        selected_provider: nil,
        is_open: true,
        current_tab: "provider"
      }

      html = render_component(&GameSettingsModal.game_settings_modal/1, assigns)

      assert html =~ "Game Settings"
      assert html =~ "AI Provider"
      assert html =~ "Select which AI provider"
      assert html =~ "Test Provider"
      refute html =~ "Public games will be visible"
    end

    test "renders events tab when selected" do
      rounds = [
        %Round{
          situation: "You hired a developer",
          inserted_at: ~N[2023-01-01 00:00:00]
        },
        %Round{
          situation: "You secured funding",
          inserted_at: ~N[2023-01-02 00:00:00]
        }
      ]

      assigns = %{
        id: "test-modal",
        game: %Game{
          is_public: true,
          is_leaderboard_eligible: false,
          provider_preference: "StartupGame.Engine.LLMScenarioProvider"
        },
        rounds: rounds,
        available_providers: [],
        selected_provider: nil,
        is_open: true,
        current_tab: "events"
      }

      html = render_component(&GameSettingsModal.game_settings_modal/1, assigns)

      assert html =~ "Game Settings"
      assert html =~ "Recent Game Events"
      assert html =~ "You hired a developer"
      assert html =~ "You secured funding"
      assert html =~ "Round Event"
      refute html =~ "Make this game public"
    end

    test "renders empty events message when no events" do
      assigns = %{
        id: "test-modal",
        game: %Game{
          is_public: true,
          is_leaderboard_eligible: false,
          provider_preference: "StartupGame.Engine.LLMScenarioProvider"
        },
        rounds: [],
        available_providers: [],
        selected_provider: nil,
        is_open: true,
        current_tab: "events"
      }

      html = render_component(&GameSettingsModal.game_settings_modal/1, assigns)

      assert html =~ "Recent Game Events"
      assert html =~ "No recent events"
    end
  end
end
