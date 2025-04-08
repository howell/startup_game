defmodule StartupGameWeb.GameLive.Components.Shared.GameLayoutComponent do
  @moduledoc """
  Shared layout component for game interfaces with responsive design.
  Used by both GamePlayComponent and GameCreationComponent.
  """
  use StartupGameWeb, :html

  @doc """
  Renders a consistent game interface layout with state panel and content area.
  """
  attr :is_mobile_state_visible, :boolean, default: false
  slot :state_panel, required: true
  slot :mobile_state_panel, required: true
  slot :content_area, required: true

  def game_layout(assigns) do
    ~H"""
    <div class="h-[calc(100vh-6rem)] w-screen flex flex-col overflow-hidden">
      <!-- Mobile toggle for game state -->
      <button
        class="lg:hidden silly-button-secondary mb-4 flex items-center justify-center"
        phx-click="toggle_mobile_state"
      >
        {if @is_mobile_state_visible, do: "Hide Game State", else: "Show Game State"}
      </button>

      <div class="flex flex-1 overflow-hidden">
        <!-- Game state panel component (for desktop) -->
        <div class="hidden lg:block lg:w-1/3 xl:w-1/4 flex-shrink-0 border-r border-b border-gray-200">
          {render_slot(@state_panel)}
        </div>
        
    <!-- Mobile game state panel (toggleable) -->
        <div :if={@is_mobile_state_visible} class="block w-full">
          {render_slot(@mobile_state_panel)}
        </div>
        
    <!-- Content area -->
        <div :if={!@is_mobile_state_visible} class="flex-1 border border-b border-gray-200 block">
          {render_slot(@content_area)}
        </div>
      </div>
    </div>
    """
  end
end
