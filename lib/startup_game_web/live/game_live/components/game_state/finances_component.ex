defmodule StartupGameWeb.GameLive.Components.GameState.FinancesComponent do
  @moduledoc """
  Component for rendering the company finances section with stat cards.
  """
  use StartupGameWeb, :html

  alias StartupGameWeb.GameLive.Helpers.GameFormatters
  alias StartupGameWeb.GameLive.Components.Shared.Icons
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
        <.stat_card value={"$#{GameFormatters.format_money(@game.cash_on_hand)}"} label="Cash">
          <Icons.cash_icon size={icon_size()} />
        </.stat_card>

        <.stat_card value={"$#{GameFormatters.format_money(@game.burn_rate)}/mo"} label="Burn Rate">
          <Icons.burn_icon size={icon_size()} />
        </.stat_card>

        <.stat_card
          value={GameFormatters.format_runway(Games.calculate_runway(@game))}
          label="Runway (months)"
        >
          <Icons.runway_icon size={icon_size()} />
        </.stat_card>

        <%= if @game.exit_type in [:acquisition, :ipo] do %>
          <.stat_card value={"$#{GameFormatters.format_money(@game.exit_value)}"} label="Exit Value">
            <Icons.trophy_icon size={icon_size()} />
          </.stat_card>
        <% else %>
          <.stat_card value={length(@ownerships)} label="Stakeholders">
            <Icons.stakeholder_icon size={icon_size()} />
          </.stat_card>
        <% end %>
      </div>
    </div>
    """
  end

  attr :value, :any, required: true
  attr :label, :string, required: true
  slot :inner_block, required: true

  defp stat_card(assigns) do
    ~H"""
    <div class="silly-stat-card">
      {render_slot(@inner_block)}
      <div>
        <div class="font-bold">{@value}</div>
        <div class="text-xs text-foreground/70">{@label}</div>
      </div>
    </div>
    """
  end

  defp icon_size, do: :lg
end
