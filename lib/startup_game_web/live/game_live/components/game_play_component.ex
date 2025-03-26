defmodule StartupGameWeb.GameLive.Components.GamePlayComponent do
  @moduledoc """
  Component for rendering the game play interface with chat, company info, and financials.
  This component coordinates the game state panel and chat interface components.
  """
  use StartupGameWeb, :html

  alias StartupGameWeb.GameLive.Components.GameState.GameStatePanelComponent
  alias StartupGameWeb.GameLive.Components.Chat.ChatInterfaceComponent
  alias StartupGameWeb.GameLive.Components.Shared.GameLayoutComponent

  @doc """
  Renders the game play interface with chat, company info, and financials.
  """
  attr :game, :map, required: true
  attr :game_state, :map, required: true
  attr :rounds, :list, required: true
  attr :ownerships, :list, required: true
  attr :response, :string, default: ""
  attr :streaming, :boolean, default: false
  attr :partial_content, :string, default: ""
  attr :streaming_type, :atom, default: nil
  attr :is_mobile_state_visible, :boolean, default: false

  def game_play(assigns) do
    ~H"""
    <GameLayoutComponent.game_layout is_mobile_state_visible={@is_mobile_state_visible}>
      <:state_panel>
        <GameStatePanelComponent.game_state_panel
          game={@game}
          is_visible={true}
          ownerships={@ownerships}
          rounds={@rounds}
        />
      </:state_panel>

      <:mobile_state_panel>
        <GameStatePanelComponent.game_state_panel
          game={@game}
          is_visible={true}
          ownerships={@ownerships}
          rounds={@rounds}
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
        />
      </:content_area>
    </GameLayoutComponent.game_layout>
    """
  end
end
