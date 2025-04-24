defmodule StartupGameWeb.GameLive.Components.GamePlayComponent do
  @moduledoc """
  Component for rendering the game play interface with chat, company info, and financials.
  This component coordinates the game state panel and chat interface components.
  """
  use StartupGameWeb, :html

  alias StartupGame.Games.Game
  alias StartupGameWeb.GameLive.Components.GameState.GameStatePanelComponent
  alias StartupGameWeb.GameLive.Components.Chat.ChatInterfaceComponent
  alias StartupGameWeb.GameLive.Components.Shared.GameLayoutComponent
  alias StartupGameWeb.GameLive.Components.GameState.CondensedGameStatePanel
  alias StartupGameWeb.GameLive.Components.GameSettings.GameSettingsModal

  @doc """
  Renders the game play interface with chat, company info, and financials.
  """
  attr :game, Game, required: true
  attr :rounds, :list, required: true
  attr :ownerships, :list, required: true
  attr :response, :string, default: ""
  attr :streaming, :boolean, default: false
  attr :partial_content, :string, default: ""
  attr :streaming_type, :atom, default: nil
  attr :is_mobile_state_visible, :boolean, default: false
  attr :is_view_only, :boolean, default: false
  attr :is_mobile_panel_expanded, :boolean, default: false
  attr :is_settings_modal_open, :boolean, default: false
  attr :active_settings_tab, :any, default: nil

  def game_play(assigns) do
    ~H"""
    <GameLayoutComponent.game_layout is_mobile_state_visible={@is_mobile_state_visible}>
      <:state_panel>
        <GameStatePanelComponent.game_state_panel
          game={@game}
          is_visible={true}
          ownerships={@ownerships}
          rounds={@rounds}
          id_prefix="main"
          is_view_only={@is_view_only}
        />
      </:state_panel>

      <:condensed_panel>
        <div class={[
          "md:hidden w-full relative",
          @is_mobile_panel_expanded && "pb-[50vh]"
        ]}>
          <CondensedGameStatePanel.condensed_game_state_panel
            id="mobile-condensed-panel"
            game={@game}
            ownerships={@ownerships}
            rounds={@rounds}
            is_expanded={@is_mobile_panel_expanded}
          />
        </div>
        <%= if @is_settings_modal_open do %>
          <GameSettingsModal.game_settings_modal
            id="settings-modal"
            game={@game}
            rounds={@rounds}
            selected_provider={@game.provider_preference}
            available_providers={get_available_providers(@game.provider_preference)}
            is_open={@is_settings_modal_open}
            current_tab={@active_settings_tab || "settings"}
          />
        <% end %>
      </:condensed_panel>

      <:content_area>
        <div class={[
          "flex-1 flex flex-col overflow-hidden relative",
          "transition-all duration-300 ease-in-out",
          @is_mobile_panel_expanded && "max-h-[50vh] md:max-h-none"
        ]}>
          <ChatInterfaceComponent.chat_interface
            game={@game}
            rounds={@rounds}
            response={@response}
            streaming={@streaming}
            streaming_type={@streaming_type}
            partial_content={@partial_content}
            is_view_only={@is_view_only}
            player_mode={@game.current_player_mode}
          />
        </div>
      </:content_area>
    </GameLayoutComponent.game_layout>
    """
  end

  # Helper function to get available providers
  defp get_available_providers(current_provider) do
    providers = [
      "OpenAI",
      "Anthropic",
      "Local Model"
    ]

    # Ensure the current provider is included in the list
    if current_provider && current_provider not in providers do
      [current_provider | providers]
    else
      providers
    end
  end
end
