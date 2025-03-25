defmodule StartupGameWeb.GameLive.Components.GamePlayComponent do
  @moduledoc """
  Component for rendering the game play interface with chat, company info, and financials.
  This component coordinates the game state panel and chat interface components.
  """
  use StartupGameWeb, :html

  alias StartupGameWeb.GameLive.Components.GameState.GameStatePanelComponent
  alias StartupGameWeb.GameLive.Components.Chat.ChatInterfaceComponent

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
    <div class="flex flex-col lg:flex-row gap-6 h-dvh">
      <!-- Mobile toggle for game state -->
      <button
        class="lg:hidden silly-button-secondary mb-4 flex items-center justify-center"
        phx-click="toggle_mobile_state"
      >
        <%= if @is_mobile_state_visible, do: "Hide Game State", else: "Show Game State" %>
      </button>

      <!-- Game state panel component -->
      <GameStatePanelComponent.game_state_panel
        game={@game}
        is_visible={@is_mobile_state_visible}
        ownerships={@ownerships}
        rounds={@rounds}
      />

      <!-- Chat interface component -->
      <ChatInterfaceComponent.chat_interface
        game={@game}
        rounds={@rounds}
        response={@response}
        streaming={@streaming}
        streaming_type={@streaming_type}
        partial_content={@partial_content}
      />
    </div>
    """
  end
end
