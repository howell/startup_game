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
      class="condensed-game-state-panel-container w-full border-t border-b border-gray-200 bg-gray-50 text-sm flex flex-col"
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
    <div class="p-2">
      <button
        phx-click="toggle_panel_expansion"
        phx-target="#game-play"
        class="w-full text-left py-2 px-3 font-medium bg-white hover:bg-gray-50 rounded-lg shadow-sm border border-gray-200 transition flex items-center justify-between focus:outline-none focus:ring-2 focus:ring-primary"
        aria-expanded="false"
      >
        <div class="flex-1 truncate">
          {@game.name} • ${GameFormatters.format_money(@game.cash_on_hand)} • {GameFormatters.format_runway(
            Games.calculate_runway(@game)
          )}mo runway •
          <span class="text-gray-600">
            You: {format_ownership_percentage(get_founder_percentage(@ownerships))}
          </span>
          |
          <span class="text-gray-600">
            Inv: {format_ownership_percentage(get_investor_percentage(@ownerships))}
          </span>
        </div>
        <CoreComponents.icon name="hero-chevron-down-mini" class="w-4 h-4 ml-2" />
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
          phx-target="#game-play"
          class="w-full text-left py-2 px-3 font-bold flex items-center hover:bg-gray-100 rounded transition focus:outline-none focus:ring-2 focus:ring-primary"
          aria-expanded="true"
        >
          <span class="flex-1">{@game_name}</span>
          <CoreComponents.icon name="hero-chevron-up-mini" class="w-4 h-4 ml-2" />
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
        <CoreComponents.icon name="hero-banknotes-mini" class="w-4 h-4 ml-1" />
      </.section_header>
      <.data_list>
        <.data_list_item label="Cash" value={"$#{GameFormatters.format_money(@game.cash_on_hand)}"} />
        <.data_list_item
          label="Monthly Burn"
          value={"$#{GameFormatters.format_money(@game.burn_rate)}"}
        />
        <.data_list_item
          label="Runway"
          value={"#{GameFormatters.format_runway(Games.calculate_runway(@game))} months"}
        />
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
        <CoreComponents.icon name="hero-users-mini" class="w-4 h-4 ml-1" />
      </.section_header>
      <.data_list>
        <%= for ownership <- @ownerships do %>
          <.data_list_item
            label={GameFormatters.format_entity_name(ownership.entity_name)}
            value={format_ownership_percentage(ownership.percentage)}
          />
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

  def data_list_item(assigns) do
    ~H"""
    <div class="flex justify-between py-2 text-sm">
      <dt class="text-gray-600">{@label}:</dt>
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
        phx-target="#game-play"
        class="silly-button-secondary text-sm"
      >
        <CoreComponents.icon name="hero-cog-6-tooth-mini" class="w-4 h-4 mr-1" />
        <span>Settings</span>
      </CoreComponents.button>
    </div>
    """
  end

  @doc """
  Format an ownership percentage value for display.
  This is slightly different from regular percentages because
  ownership values are stored as decimals (0.0-1.0) but displayed as percentages.
  """
  @spec format_ownership_percentage(Decimal.t() | float()) :: String.t()
  def format_ownership_percentage(%Decimal{} = percentage) do
    # Convert to a percentage (0-100 scale)
    percentage_value = Decimal.mult(percentage, Decimal.new(100))
    "#{Decimal.round(percentage_value, 1)}%"
  end

  def format_ownership_percentage(percentage) when is_float(percentage) do
    "#{Float.round(percentage * 100, 1)}%"
  end

  @doc """
  Get the founder's ownership percentage.
  """
  @spec get_founder_percentage([Ownership.t()]) :: Decimal.t() | float()
  def get_founder_percentage(ownerships) do
    case Enum.find(ownerships, fn o -> String.downcase(o.entity_name) == "founder" end) do
      nil -> 1.0
      ownership -> ownership.percentage
    end
  end

  @doc """
  Get the combined investor ownership percentage.
  """
  @spec get_investor_percentage([Ownership.t()]) :: Decimal.t() | float()
  def get_investor_percentage(ownerships) do
    founder_percentage = get_founder_percentage(ownerships)

    # Handle both Decimal and float
    if is_float(founder_percentage) do
      1.0 - founder_percentage
    else
      Decimal.sub(Decimal.new(1), founder_percentage)
    end
  end
end
