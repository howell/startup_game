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

  def game_state_panel(assigns) do
    ~H"""
    <div class={"#{if @is_visible, do: "block", else: "hidden"} h-full overflow-hidden flex flex-col"}>
      <div class="glass-card flex-1 overflow-y-auto p-5">
        <.company_header game={@game} />

        <div class="space-y-6">
          <FinancesComponent.finances_section game={@game} ownerships={@ownerships} />
          <OwnershipComponent.ownership_section ownerships={@ownerships} />
          <ProviderSelector.provider_selector game={@game} />
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
            <div class="text-sm bg-white bg-opacity-50 rounded-lg p-2 flex items-start">
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
end
