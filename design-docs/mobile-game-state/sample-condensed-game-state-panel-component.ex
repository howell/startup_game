defmodule StartupGameWeb.GameLive.Components.GameState.CondensedGameStatePanelComponent do
  @moduledoc """
  Component for rendering a condensed game state panel on mobile devices.
  Displays essential game information in a compact format that can be expanded/collapsed.
  """
  use StartupGameWeb, :html

  alias StartupGameWeb.GameLive.Helpers.GameFormatters
  alias StartupGame.Games

  @type t :: map()

  @doc """
  Renders the condensed game state panel.

  ## Attributes

  * `game` - The game struct with company information
  * `ownerships` - List of ownership records
  * `is_expanded` - Whether the panel is in expanded state
  * `id_prefix` - Prefix for HTML IDs to avoid collisions
  """
  attr :game, :map, required: true
  attr :ownerships, :list, required: true
  attr :is_expanded, :boolean, default: false
  attr :id_prefix, :string, default: "mobile"

  def condensed_game_state_panel(assigns) do
    ~H"""
    <div
      id={"#{@id_prefix}-condensed-panel"}
      class={[
        "mobile-condensed-panel",
        "transition-all duration-300 ease-in-out",
        @is_expanded && "mobile-condensed-panel-expanded"
      ]}
    >
      <%= if @is_expanded do %>
        <.expanded_panel game={@game} ownerships={@ownerships} id_prefix={@id_prefix} />
      <% else %>
        <.collapsed_panel game={@game} ownerships={@ownerships} />
      <% end %>
    </div>
    """
  end

  @doc """
  Renders the collapsed view of the panel with summary information.
  """
  attr :game, :map, required: true
  attr :ownerships, :list, required: true

  def collapsed_panel(assigns) do
    founder_pct = calculate_founder_percentage(assigns.ownerships)
    investor_pct = 100 - founder_pct

    ~H"""
    <div
      class="flex items-center justify-between px-3 py-2 border-t border-b border-gray-200 bg-white bg-opacity-80 shadow-sm"
      phx-click="toggle_panel_expansion"
    >
      <div class="flex items-center space-x-2 overflow-hidden">
        <.icon name="hero-chevron-down" class="h-4 w-4 text-gray-500 flex-shrink-0" />
        <span class="font-medium truncate"><%= @game.name %></span>
        <span class="text-sm text-gray-600">•</span>
        <span class="text-sm text-gray-600 whitespace-nowrap">
          <%= GameFormatters.format_money(@game.cash_on_hand) %>
        </span>
        <span class="text-sm text-gray-600">•</span>
        <span class="text-sm text-gray-600 whitespace-nowrap">
          <%= GameFormatters.format_runway(Games.calculate_runway(@game)) %> runway
        </span>
      </div>
      <div class="flex-shrink-0 text-sm text-gray-600 whitespace-nowrap">
        You: <%= founder_pct %>% | Inv: <%= investor_pct %>%
      </div>
    </div>
    """
  end

  @doc """
  Renders the expanded view of the panel with detailed information.
  """
  attr :game, :map, required: true
  attr :ownerships, :list, required: true
  attr :id_prefix, :string, default: "mobile"

  def expanded_panel(assigns) do
    ~H"""
    <div class="bg-white bg-opacity-90 border-t border-b border-gray-200 shadow-md">
      <div
        class="flex items-center justify-between px-3 py-2 border-b border-gray-200 cursor-pointer"
        phx-click="toggle_panel_expansion"
      >
        <div class="flex items-center">
          <.icon name="hero-chevron-up" class="h-4 w-4 text-gray-500 mr-2" />
          <h3 class="font-medium"><%= @game.name %></h3>
        </div>
      </div>

      <div class="p-3 space-y-4 max-h-[50vh] overflow-y-auto">
        <!-- Finances Section -->
        <div>
          <h4 class="text-xs font-semibold text-gray-500 mb-1">FINANCES</h4>
          <div class="grid grid-cols-2 gap-2">
            <div>
              <div class="text-xs text-gray-500">Cash</div>
              <div class="font-medium"><%= GameFormatters.format_money(@game.cash_on_hand) %></div>
            </div>
            <div>
              <div class="text-xs text-gray-500">Monthly Burn</div>
              <div class="font-medium"><%= GameFormatters.format_money(@game.monthly_burn) %></div>
            </div>
            <div>
              <div class="text-xs text-gray-500">Runway</div>
              <div class="font-medium"><%= GameFormatters.format_runway(Games.calculate_runway(@game)) %> months</div>
            </div>
            <div>
              <div class="text-xs text-gray-500">Revenue</div>
              <div class="font-medium"><%= GameFormatters.format_money(@game.monthly_revenue) %>/mo</div>
            </div>
          </div>
        </div>

        <!-- Ownership Section -->
        <div>
          <h4 class="text-xs font-semibold text-gray-500 mb-1">OWNERSHIP</h4>
          <div class="space-y-1">
            <%= for ownership <- @ownerships do %>
              <div class="flex justify-between items-center">
                <span class="text-sm"><%= ownership.owner_name %></span>
                <span class="text-sm font-medium"><%= format_percentage(ownership.percentage) %>%</span>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Metrics Section -->
        <div>
          <h4 class="text-xs font-semibold text-gray-500 mb-1">METRICS</h4>
          <div class="grid grid-cols-2 gap-2">
            <div>
              <div class="text-xs text-gray-500">Users</div>
              <div class="font-medium">
                <%= format_number(@game.users) %>
                <%= if @game.user_growth_rate > 0 do %>
                  <span class="text-green-600 text-xs">(+<%= format_percentage(@game.user_growth_rate) %>%)</span>
                <% end %>
              </div>
            </div>
            <div>
              <div class="text-xs text-gray-500">MRR</div>
              <div class="font-medium"><%= GameFormatters.format_money(@game.monthly_recurring_revenue) %></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Settings Button -->
      <div class="px-3 py-2 border-t border-gray-200">
        <button
          class="w-full py-1 px-3 bg-gray-100 hover:bg-gray-200 rounded text-sm font-medium flex items-center justify-center transition-colors"
          phx-click="toggle_settings_modal"
        >
          <.icon name="hero-cog-6-tooth" class="h-4 w-4 mr-1" />
          <span>Settings</span>
        </button>
      </div>
    </div>
    """
  end

  # Helper functions

  @spec calculate_founder_percentage(list()) :: integer()
  defp calculate_founder_percentage(ownerships) do
    ownerships
    |> Enum.find(fn o -> o.owner_type == :founder end)
    |> case do
      nil -> 100
      ownership -> round(ownership.percentage)
    end
  end

  @spec format_percentage(float()) :: String.t()
  defp format_percentage(value) do
    value |> Float.round(1) |> :erlang.float_to_binary(decimals: 1)
  end

  @spec format_number(integer()) :: String.t()
  defp format_number(value) when value >= 1_000_000 do
    "#{round(value / 1_000_000)}M"
  end

  defp format_number(value) when value >= 1_000 do
    "#{round(value / 1_000)}K"
  end

  defp format_number(value) do
    "#{value}"
  end
end
