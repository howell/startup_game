defmodule StartupGameWeb.GameLive.Components.GameState.FinancesComponent do
  @moduledoc """
  Component for rendering the company finances section with stat cards.
  """
  use StartupGameWeb, :html

  alias StartupGameWeb.GameLive.Helpers.GameFormatters
  alias StartupGame.Games

  @doc """
  Renders the finances section with title and stat cards grid
  """
  attr :game, :map, required: true
  attr :ownerships, :list, required: true

  def finances_section(assigns) do
    ~H"""
    <div>
      <h3 class="text-sm font-semibold text-foreground/70 mb-3">COMPANY FINANCES</h3>
      <div class="grid grid-cols-2 gap-3">
        <.stat_card
          icon="hero-currency-dollar"
          icon_class="text-silly-success"
          value={"$#{GameFormatters.format_money(@game.cash_on_hand)}"}
          label="Cash"
        />

        <.stat_card
          icon="hero-arrow-trending-down"
          icon_class="text-silly-accent"
          value={"$#{GameFormatters.format_money(@game.burn_rate)}/mo"}
          label="Burn Rate"
        />

        <.stat_card
          icon="hero-exclamation-triangle"
          icon_class="text-silly-yellow"
          value={GameFormatters.format_runway(Games.calculate_runway(@game))}
          label="Runway (months)"
        />

        <%= if @game.exit_type in [:acquisition, :ipo] do %>
          <.stat_card
            icon="hero-trophy"
            icon_class="text-silly-success"
            value={"$#{GameFormatters.format_money(@game.exit_value)}"}
            label="Exit Value"
          />
        <% else %>
          <.stat_card
            icon="hero-building-office-2"
            icon_class="text-silly-blue"
            value={length(@ownerships)}
            label="Stakeholders"
          />
        <% end %>
      </div>
    </div>
    """
  end

  attr :icon, :string, required: true
  attr :icon_class, :string, default: "text-silly-accent"
  attr :value, :any, required: true
  attr :label, :string, required: true

  defp stat_card(assigns) do
    ~H"""
    <div class="silly-stat-card">
      <.icon name={@icon} class={@icon_class} />
      <div>
        <div class="font-bold"><%= @value %></div>
        <div class="text-xs text-foreground/70"><%= @label %></div>
      </div>
    </div>
    """
  end
end
