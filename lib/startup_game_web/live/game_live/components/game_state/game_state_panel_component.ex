defmodule StartupGameWeb.GameLive.Components.GameState.GameStatePanelComponent do
  @moduledoc """
  Component for rendering the game state panel with company info, finances, and ownership.
  """
  use StartupGameWeb, :html

  alias StartupGameWeb.GameLive.Components.Shared.ProviderSelector
  alias StartupGameWeb.GameLive.Components.GameState.FinancesComponent
  alias StartupGameWeb.GameLive.Components.GameState.OwnershipComponent
  alias StartupGameWeb.GameLive.Helpers.GameFormatters
  alias StartupGame.Games

  @doc """
  Renders the game state panel with all sections
  """
  attr :game, :map, required: true
  attr :is_visible, :boolean, default: true
  attr :ownerships, :list, required: true
  attr :rounds, :list, required: true
  attr :id_prefix, :string, default: "main"
  attr :is_view_only, :boolean, default: false

  def game_state_panel(assigns) do
    ~H"""
    <div class={"#{if @is_visible, do: "block", else: "hidden"} h-full overflow-hidden flex flex-col"}>
      <div class="glass-card flex-1 overflow-y-auto p-5">
        <.company_header game={@game} />

        <div class="space-y-6">
          <FinancesComponent.finances_section game={@game} ownerships={@ownerships} />
          <OwnershipComponent.ownership_section ownerships={@ownerships} />
          <%= unless @is_view_only do %>
            <ProviderSelector.provider_selector game={@game} />
            <.visibility_settings_section game={@game} id_prefix={@id_prefix} />
          <% end %>
          <.recent_events_section rounds={@rounds} />
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the company header with name, description, and financial summary
  """
  attr :game, :map, required: true

  def company_header(assigns) do
    ~H"""
    <div class="mb-6">
      <h2 class="heading-md mb-1">{@game.name}</h2>
      <p class="text-foreground/70 text-sm mb-2">{@game.description}</p>
      <div class="flex items-center gap-2 text-foreground/70">
        <.icon name="hero-arrow-trending-up" class="text-silly-accent" />
        <p>
          ${GameFormatters.format_money(@game.cash_on_hand)} • Runway: {GameFormatters.format_runway(
            Games.calculate_runway(@game)
          )} months
        </p>
      </div>
    </div>
    """
  end

  @doc """
  Renders the recent events section with last few rounds
  """
  attr :rounds, :list, required: true

  def recent_events_section(assigns) do
    ~H"""
    <div>
      <h3 class="text-sm font-semibold text-foreground/70 mb-3">RECENT EVENTS</h3>
      <div class="space-y-2">
        <%= for i <- 1..3 do %>
          <%= if Enum.at(@rounds, -i) do %>
            <% round = Enum.at(@rounds, -i) %>
            <div
              :if={round.situation}
              class="text-sm bg-white bg-opacity-50 rounded-lg p-2 flex items-start"
            >
              <div class="bg-silly-blue/10 rounded-full p-1 mr-2 mt-0.5">
                <.icon name="hero-star" class="h-3 w-3 text-silly-blue" />
              </div>
              {String.slice(round.situation, 0, 60) <>
                if String.length(round.situation) > 60, do: "...", else: ""}
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders the visibility settings section
  """
  attr :game, :map, required: true
  attr :id_prefix, :string, default: "main"

  def visibility_settings_section(assigns) do
    ~H"""
    <div>
      <h3 class="text-sm font-semibold text-foreground/70 mb-3">VISIBILITY SETTINGS</h3>
      <div class="space-y-2">
        <div class="flex items-center justify-between p-2 bg-white/50 rounded-lg">
          <span class="text-sm">Public Game</span>
          <div class="form-control">
            <input
              id={"game-public-toggle-#{@id_prefix}"}
              type="checkbox"
              checked={@game.is_public}
              phx-click="toggle_visibility"
              phx-value-field="is_public"
              class="toggle toggle-sm toggle-primary"
            />
          </div>
        </div>
        <div class="flex items-center justify-between p-2 bg-white/50 rounded-lg">
          <span class="text-sm">Leaderboard Eligible</span>
          <div class="form-control">
            <input
              id={"game-leaderboard-toggle-#{@id_prefix}"}
              type="checkbox"
              checked={@game.is_leaderboard_eligible}
              phx-click="toggle_visibility"
              phx-value-field="is_leaderboard_eligible"
              class="toggle toggle-sm toggle-primary"
              disabled={!@game.is_public}
            />
          </div>
        </div>
        <div class="text-xs text-foreground/50 mt-1">
          Public games can be viewed by others. Eligible games appear on the leaderboard when completed.
        </div>
      </div>
    </div>
    """
  end
end
