defmodule StartupGameWeb.GameLive.Components.GameState.CondensedGameStatePanel do
  use StartupGameWeb, :html

  @moduledoc """
  Component for the condensed game state panel used in mobile view.
  Shows critical game information in both collapsed and expanded states.
  """

  alias StartupGame.Games
  alias StartupGame.Games.{Game, Ownership}
  alias StartupGameWeb.GameLive.Helpers.GameFormatters
  alias StartupGameWeb.CoreComponents
  alias StartupGameWeb.GameLive.Components.Shared.Icons

  @doc """
  Renders the condensed game state panel with finances and ownership.

  ## Attributes
    * `id` - The ID of the panel element
    * `game` - The game struct with financial and company data
    * `ownerships` - List of ownership records
    * `rounds` - List of game rounds
    * `is_expanded` - Whether the panel is currently expanded
  """
  attr :id, :string, required: true
  attr :game, Game, required: true
  attr :ownerships, :list, required: true
  attr :rounds, :list, required: true
  attr :is_expanded, :boolean, default: false

  def condensed_game_state_panel(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "w-full border-t border-b border-gray-200 bg-gray-50 text-sm flex flex-col",
        "sticky bottom-0 z-10 shadow-[0_-2px_10px_rgba(0,0,0,0.05)] transition-all duration-300 ease-in-out",
        @is_expanded && "bg-white",
        !@is_expanded && "max-h-[60px] overflow-hidden"
      ]}
      aria-expanded={@is_expanded}
    >
      <%= if @is_expanded do %>
        <.expanded_panel game={@game} ownerships={@ownerships} />
      <% else %>
        <.collapsed_panel game={@game} ownerships={@ownerships} />
      <% end %>
    </div>
    """
  end

  @doc """
  Renders the expanded panel view with detailed information.
  """
  attr :game, Game, required: true
  attr :ownerships, :list, required: true

  def expanded_panel(assigns) do
    ~H"""
    <div class="flex flex-col animate-expandPanel max-h-[50vh] overflow-y-auto">
      <.panel_header game_name={@game.name} />
      <div class="p-3 flex flex-col gap-4 overflow-y-auto">
        <.finances_section game={@game} />
        <.ownership_section ownerships={@ownerships} />
      </div>
      <.panel_footer />
    </div>
    """
  end

  @doc """
  Renders the collapsed panel with summary information.
  """
  attr :game, Game, required: true
  attr :ownerships, :list, required: true

  def collapsed_panel(assigns) do
    ~H"""
    <div class="p-2 animate-fadeIn">
      <button
        phx-click="toggle_panel_expansion"
        class="w-full text-left py-2 px-3 font-medium bg-white hover:bg-gray-50 rounded-lg shadow-sm border border-gray-200 transition-colors flex items-center justify-between focus:outline-none focus:ring-2 focus:ring-primary"
        aria-expanded="false"
      >
        <div class="flex flex-row truncate w-full justify-between">
          <span class="font-semibold">{@game.name}</span>
          <div class="flex items-center">
            <Icons.cash_icon size={:sm} class="mr-1" />
            <span>${GameFormatters.format_money(@game.cash_on_hand)}</span>
          </div>
          <div class="flex items-center">
            <Icons.burn_icon size={:sm} class="mr-1" />
            <span>${GameFormatters.format_money(@game.burn_rate)}/month</span>
          </div>
          <div class="flex items-center">
            <Icons.runway_icon size={:sm} class="mr-1" />
            <span>{GameFormatters.format_runway(Games.calculate_runway(@game))} months</span>
          </div>
          <div class="flex items-center">
            <Icons.founder_icon size={:sm} class="mr-1" />
            <span>You: {GameFormatters.format_percentage(get_founder_percentage(@ownerships))}%</span>
          </div>
          <div class="flex items-center">
            <Icons.stakeholder_icon size={:sm} class="mr-1" />
            <span>
              Others: {GameFormatters.format_percentage(get_investor_percentage(@ownerships))}%
            </span>
          </div>
        </div>
        <div class="min-h-[44px] min-w-[44px] flex items-center justify-center">
          <Icons.chevron_down_icon size={:md} class="ml-2" />
        </div>
      </button>
    </div>
    """
  end

  @doc """
  Renders the panel header with game name and toggle button.
  """
  attr :game_name, :string, required: true

  def panel_header(assigns) do
    ~H"""
    <div class="sticky top-0 z-10 bg-gray-50 border-b border-gray-200 p-2">
      <CoreComponents.header class="p-0 m-0">
        <button
          phx-click="toggle_panel_expansion"
          class="w-full text-left py-2 px-3 font-bold flex items-center hover:bg-gray-100 rounded transition-colors focus:outline-none focus:ring-2 focus:ring-primary"
          aria-expanded="true"
        >
          <span class="flex-1">{@game_name}</span>
          <div class="min-h-[44px] min-w-[44px] flex items-center justify-center">
            <Icons.chevron_up_icon size={:md} class="ml-2" />
          </div>
        </button>
      </CoreComponents.header>
    </div>
    """
  end

  @doc """
  Renders the finances section of the panel.
  """
  attr :game, Game, required: true

  def finances_section(assigns) do
    ~H"""
    <div class="mt-2">
      <.section_header title="FINANCES">
        <Icons.cash_icon size={:sm} class="ml-1" />
      </.section_header>
      <.data_list>
        <.data_list_item label="Cash" value={"$#{GameFormatters.format_money(@game.cash_on_hand)}"}>
          <Icons.cash_icon size={:sm} class="mr-1" />
        </.data_list_item>
        <.data_list_item
          label="Monthly Burn"
          value={"$#{GameFormatters.format_money(@game.burn_rate)}"}
        >
          <Icons.burn_icon size={:sm} class="mr-1" />
        </.data_list_item>
        <.data_list_item
          label="Runway"
          value={"#{GameFormatters.format_runway(Games.calculate_runway(@game))} months"}
        >
          <Icons.runway_icon size={:sm} class="mr-1" />
        </.data_list_item>
      </.data_list>
    </div>
    """
  end

  @doc """
  Renders the ownership section of the panel.
  """
  attr :ownerships, :list, required: true

  def ownership_section(assigns) do
    ~H"""
    <div class="mt-2">
      <.section_header title="OWNERSHIP">
        <Icons.stakeholder_icon size={:sm} class="ml-1" />
      </.section_header>
      <.data_list>
        <%= for ownership <- @ownerships do %>
          <.data_list_item
            label={GameFormatters.format_entity_name(ownership.entity_name)}
            value={"#{GameFormatters.format_percentage(ownership.percentage)}%"}
          >
            <%= if String.downcase(ownership.entity_name) == "founder" do %>
              <Icons.founder_icon size={:sm} class="mr-1" />
            <% else %>
              <Icons.stakeholder_icon size={:sm} class="mr-1" />
            <% end %>
          </.data_list_item>
        <% end %>
      </.data_list>
    </div>
    """
  end

  @doc """
  Renders a section header with consistent styling.
  """
  attr :title, :string, required: true
  slot :inner_block, required: false

  def section_header(assigns) do
    ~H"""
    <h3 class="text-sm font-bold text-gray-500 flex items-center">
      {@title}
      {render_slot(@inner_block)}
    </h3>
    """
  end

  @doc """
  Renders a custom data list component optimized for key-value pairs.
  """
  slot :inner_block, required: true

  def data_list(assigns) do
    ~H"""
    <dl class="mt-2 divide-y divide-gray-100">
      {render_slot(@inner_block)}
    </dl>
    """
  end

  @doc """
  Renders a data list item with label and value.
  """
  attr :label, :string, required: true
  attr :value, :string, required: true
  slot :inner_block, required: true

  def data_list_item(assigns) do
    ~H"""
    <div class="flex justify-between py-2 text-sm">
      <dt class="text-gray-600 flex items-center">
        {render_slot(@inner_block)}
        {@label}:
      </dt>
      <dd class="font-medium text-gray-900">{@value}</dd>
    </div>
    """
  end

  @doc """
  Renders the panel footer with settings button.
  """
  def panel_footer(assigns) do
    ~H"""
    <div class="sticky bottom-0 bg-gray-50 border-t border-gray-200 p-2 flex justify-center">
      <CoreComponents.button
        phx-click="toggle_settings_modal"
        class="silly-button-secondary text-sm w-full min-h-[44px] flex items-center justify-center"
      >
        <Icons.settings_icon size={:sm} class="mr-1" />
        <span>Settings</span>
      </CoreComponents.button>
    </div>
    """
  end

  @doc """
  Get the founder's ownership percentage.
  """
  @spec get_founder_percentage([Ownership.t()]) :: Decimal.t()
  def get_founder_percentage(ownerships) do
    case Enum.find(ownerships, fn o -> String.downcase(o.entity_name) == "founder" end) do
      nil -> Decimal.new(100)
      ownership -> ownership.percentage
    end
  end

  @doc """
  Get the combined investor ownership percentage.
  """
  @spec get_investor_percentage([Ownership.t()]) :: Decimal.t()
  def get_investor_percentage(ownerships) do
    founder_percentage = get_founder_percentage(ownerships)

    Decimal.sub(Decimal.new(100), founder_percentage)
  end
end
