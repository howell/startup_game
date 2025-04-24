defmodule StartupGameWeb.GameLive.Components.GameSettings.GameSettingsModal do
  use StartupGameWeb, :html

  @moduledoc """
  Modal component for game settings and additional information.
  Provides access to game settings, provider selection, and recent events.
  """

  alias Phoenix.LiveView.JS
  alias StartupGame.Games.Game
  alias StartupGameWeb.CoreComponents

  @doc """
  Renders the game settings modal with tabs for different settings groups.

  ## Attributes
    * `id` - The ID of the modal element
    * `game` - The game struct with game settings
    * `rounds` - List of game rounds for displaying recent events
    * `available_providers` - List of available AI providers
    * `selected_provider` - Currently selected AI provider
    * `is_open` - Whether the modal is currently open
    * `current_tab` - The currently active tab
  """
  attr :id, :string, required: true
  attr :game, Game, required: true
  attr :rounds, :list, required: true
  attr :available_providers, :list, required: true
  attr :selected_provider, :any, required: true
  attr :is_open, :boolean, default: false
  attr :current_tab, :string, default: "settings"

  def game_settings_modal(assigns) do
    ~H"""
    <CoreComponents.modal
      id={@id}
      show={@is_open}
      on_cancel={JS.push("toggle_settings_modal", target: "#game-play")}
    >
      <div class="bg-white w-full">
        <CoreComponents.header>
          Game Settings
          <:actions>
            <button
              data-testid="modal-close-x"
              phx-click="toggle_settings_modal"
              phx-target="#game-play"
              class="text-gray-400 hover:text-gray-500"
            >
              <span class="sr-only">Close</span>
              <CoreComponents.icon name="hero-x-mark-solid" class="h-6 w-6" />
            </button>
          </:actions>
        </CoreComponents.header>

        <div class="border-b border-gray-200 mt-4">
          <.settings_tabs current_tab={@current_tab} />
        </div>

        <div class="mt-4">
          <%= case @current_tab do %>
            <% "settings" -> %>
              <.settings_tab_content game={@game} />
            <% "provider" -> %>
              <.provider_tab_content
                available_providers={@available_providers}
                selected_provider={@selected_provider}
              />
            <% "events" -> %>
              <.events_tab_content rounds={@rounds} />
          <% end %>
        </div>

        <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse mt-6">
          <CoreComponents.button
            data-testid="modal-close-footer"
            phx-click="toggle_settings_modal"
            phx-target="#game-play"
          >
            Close
          </CoreComponents.button>
        </div>
      </div>
    </CoreComponents.modal>
    """
  end

  @doc """
  Renders the settings tab navigation.
  """
  attr :current_tab, :string, required: true

  def settings_tabs(assigns) do
    ~H"""
    <nav class="-mb-px flex space-x-8" aria-label="Tabs">
      <.tab_button active={@current_tab == "settings"} tab_id="settings">
        Game Settings
      </.tab_button>
      <.tab_button active={@current_tab == "provider"} tab_id="provider">
        Provider
      </.tab_button>
      <.tab_button active={@current_tab == "events"} tab_id="events">
        Recent Events
      </.tab_button>
    </nav>
    """
  end

  @doc """
  Renders a tab button with consistent styling.
  """
  attr :active, :boolean, required: true
  attr :tab_id, :string, required: true
  slot :inner_block, required: true

  def tab_button(assigns) do
    ~H"""
    <button
      class={[
        "py-2 px-1 border-b-2 font-medium text-sm",
        @active && "border-primary text-primary",
        !@active && "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
      ]}
      phx-click="select_settings_tab"
      phx-value-tab={@tab_id}
      phx-target="#game-play"
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders the content for the settings tab.
  """
  attr :game, Game, required: true

  def settings_tab_content(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h3 class="text-lg font-bold mb-2">Game Visibility</h3>
        <div class="flex items-center space-x-2">
          <CoreComponents.input
            type="checkbox"
            id="game-visibility"
            name="game-visibility"
            phx-click="toggle_game_visibility"
            phx-target="#game-play"
            checked={@game.is_public}
            label="Make this game public"
          />
        </div>
        <p class="text-sm text-gray-500 mt-1">
          Public games will be visible in the public games list.
        </p>
      </div>
      <!-- Additional settings can be added here -->
    </div>
    """
  end

  @doc """
  Renders the content for the provider selection tab.
  """
  attr :available_providers, :list, required: true
  attr :selected_provider, :any, required: true

  def provider_tab_content(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h3 class="text-lg font-bold mb-2">AI Provider</h3>
        <p class="text-sm text-gray-500 mb-3">
          Select which AI provider to use for game responses:
        </p>
        <div class="space-y-2">
          <%= for provider <- @available_providers do %>
            <div class="flex items-center">
              <input
                type="radio"
                id={"provider-#{provider}"}
                name="provider"
                value={provider}
                checked={@selected_provider == provider}
                phx-click="select_provider"
                phx-value-provider={provider}
                phx-target="#game-play"
                class="h-4 w-4 border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <label
                for={"provider-#{provider}"}
                class="ml-3 block min-w-0 flex-1 p-2 text-sm text-gray-700"
              >
                <div class="text-md font-medium">{provider}</div>
                <div class="text-xs text-gray-500">{provider}</div>
              </label>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the content for the recent events tab.
  """
  attr :rounds, :list, required: true

  def events_tab_content(assigns) do
    ~H"""
    <div class="space-y-4">
      <h3 class="text-lg font-bold">Recent Game Events</h3>
      <div class="overflow-y-auto max-h-96 space-y-3">
        <%= if length(@rounds) > 0 do %>
          <%= for round <- Enum.sort(@rounds, &(NaiveDateTime.compare(&1.inserted_at, &2.inserted_at) == :gt)) do %>
            <.event_card round={round} />
          <% end %>
        <% else %>
          <p class="text-gray-500 italic">No recent events.</p>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders a card for an individual event.
  """
  attr :round, :map, required: true

  def event_card(assigns) do
    ~H"""
    <div class="bg-white p-3 rounded-md border border-gray-200">
      <div class="flex justify-between">
        <span class="font-medium">Round Event</span>
        <span class="text-sm text-gray-500">
          <%= if @round.inserted_at do %>
            {Calendar.strftime(@round.inserted_at, "%b %d, %Y")}
          <% end %>
        </span>
      </div>
      <p class="text-sm mt-1">{@round.situation}</p>
    </div>
    """
  end
end
