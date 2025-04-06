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

  @doc """
  Renders the game play interface with chat, company info, and financials.
  """
  attr :game, Game, required: true
  attr :game_state, :map, required: true
  attr :rounds, :list, required: true
  attr :ownerships, :list, required: true
  attr :response, :string, default: ""
  attr :streaming, :boolean, default: false
  attr :partial_content, :string, default: ""
  attr :streaming_type, :atom, default: nil
  attr :is_mobile_state_visible, :boolean, default: false
  attr :is_view_only, :boolean, default: false

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

      <:mobile_state_panel>
        <GameStatePanelComponent.game_state_panel
          game={@game}
          is_visible={true}
          ownerships={@ownerships}
          rounds={@rounds}
          id_prefix="mobile"
          is_view_only={@is_view_only}
        />
      </:mobile_state_panel>

      <:content_area>
        <ChatInterfaceComponent.chat_interface
          game={@game}
          rounds={@rounds}
          response={@response}
          streaming={@streaming}
          streaming_type={@streaming_type}
          partial_content={@partial_content}
          is_view_only={@is_view_only}
          player_mode={@game.current_player_mode}
          game_state={@game_state}
        />
      </:content_area>
    </GameLayoutComponent.game_layout>
    """
  end
end
