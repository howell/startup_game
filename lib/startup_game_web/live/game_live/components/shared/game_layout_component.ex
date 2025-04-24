defmodule StartupGameWeb.GameLive.Components.Shared.GameLayoutComponent do
  @moduledoc """
  Shared layout component for game interfaces with responsive design.
  Used by both GamePlayComponent and GameCreationComponent.
  """
  use StartupGameWeb, :html

  @doc """
  Renders a consistent game interface layout with state panel, condensed panel (mobile), and content area.
  """
  attr :is_mobile_state_visible, :boolean, default: false
  slot :condensed_panel, required: true
  slot :state_panel, required: true
  slot :content_area, required: true

  def game_layout(assigns) do
    ~H"""
    <div class="h-[calc(100vh-3rem)] w-screen flex flex-col overflow-hidden">
      <div class="flex flex-1 overflow-hidden">
        <!-- Game state panel component (for desktop) -->
        <div class="hidden lg:block lg:w-1/3 xl:w-1/4 flex-shrink-0 border-r border-b border-gray-200 z-10">
          {render_slot(@state_panel)}
        </div>
        <!-- Main content area (chat + condensed panel on mobile) -->
        <div class="flex-1 flex flex-col relative bg-white">
          <!-- Condensed panel for mobile, between chat and response form -->
          <div class="block lg:hidden z-20">
            {render_slot(@condensed_panel)}
          </div>
          <div class="flex-1 min-h-0 overflow-y-auto">
            {render_slot(@content_area)}
          </div>
        </div>
      </div>
    </div>
    """
  end
end
