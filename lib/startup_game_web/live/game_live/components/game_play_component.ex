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
    <div class="h-[calc(100vh-8rem)] w-screen flex flex-col overflow-hidden">
      <!-- Mobile toggle for game state -->
      <button
        class="lg:hidden silly-button-secondary mb-4 flex items-center justify-center"
        phx-click="toggle_mobile_state"
      >
        {if @is_mobile_state_visible, do: "Hide Game State", else: "Show Game State"}
      </button>

      <div class="flex flex-1 overflow-hidden">
        <!-- Game state panel component (for desktop) -->
        <div class="hidden lg:block lg:w-1/3 xl:w-1/4 flex-shrink-0 border-r border-gray-200">
          <GameStatePanelComponent.game_state_panel
            game={@game}
            is_visible={true}
            ownerships={@ownerships}
            rounds={@rounds}
          />
        </div>
        
    <!-- Mobile game state panel (toggleable) -->
        <div class={if @is_mobile_state_visible, do: "block w-full", else: "hidden"}>
          <GameStatePanelComponent.game_state_panel
            game={@game}
            is_visible={true}
            ownerships={@ownerships}
            rounds={@rounds}
          />
        </div>
        
    <!-- Chat interface component -->
        <div class="flex-1">
          <ChatInterfaceComponent.chat_interface
            game={@game}
            rounds={@rounds}
            response={@response}
            streaming={@streaming}
            streaming_type={@streaming_type}
            partial_content={@partial_content}
          />
        </div>
      </div>
    </div>
    """
  end
end
