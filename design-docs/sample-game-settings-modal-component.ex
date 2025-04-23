defmodule StartupGameWeb.GameLive.Components.GameSettings.GameSettingsModalComponent do
  @moduledoc """
  Modal component for game settings that can be displayed over the main game interface.
  Provides access to visibility settings, provider selection, and other game configuration.
  """
  use StartupGameWeb, :html

  @type t :: map()

  @doc """
  Renders the game settings modal.

  ## Attributes

  * `game` - The game struct with current settings
  * `rounds` - List of game rounds for recent events section
  * `is_open` - Whether the modal is currently open
  * `active_tab` - The currently active tab (atom)
  * `id_prefix` - Prefix for HTML IDs to avoid collisions
  """
  attr :game, :map, required: true
  attr :rounds, :list, required: true
  attr :is_open, :boolean, default: false
  attr :active_tab, :atom, default: :visibility
  attr :id_prefix, :string, default: "settings"

  def game_settings_modal(assigns) do
    ~H"""
    <div
      id={"#{@id_prefix}-modal"}
      class={[
        "fixed inset-0 z-50 flex items-center justify-center p-4",
        "transition-opacity duration-300 ease-in-out",
        if(@is_open, do: "opacity-100", else: "opacity-0 pointer-events-none")
      ]}
      role="dialog"
      aria-modal="true"
      aria-labelledby={"#{@id_prefix}-modal-title"}
      phx-window-keydown="close_settings_modal"
      phx-key="escape"
    >
      <!-- Backdrop -->
      <div
        class="absolute inset-0 bg-black bg-opacity-50"
        phx-click="toggle_settings_modal"
      />

      <!-- Modal Content -->
      <div
        class={[
          "bg-white rounded-lg shadow-xl w-full max-w-md max-h-[90vh] overflow-hidden",
          "transform transition-transform duration-300 ease-in-out",
          if(@is_open, do: "translate-y-0", else: "translate-y-4")
        ]}
      >
        <!-- Modal Header -->
        <div class="flex items-center justify-between p-4 border-b border-gray-200">
          <h2 id={"#{@id_prefix}-modal-title"} class="text-lg font-semibold">Game Settings</h2>
          <button
            class="text-gray-500 hover:text-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 rounded-full"
            aria-label="Close"
            phx-click="toggle_settings_modal"
          >
            <.icon name="hero-x-mark" class="h-5 w-5" />
          </button>
        </div>

        <!-- Tabs -->
        <div class="px-4 border-b border-gray-200">
          <div class="flex space-x-4">
            <button
              class={[
                "py-2 border-b-2 text-sm font-medium",
                if(@active_tab == :visibility, do: "border-indigo-500 text-indigo-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")
              ]}
              phx-click="select_settings_tab"
              phx-value-tab="visibility"
            >
              Visibility
            </button>
            <button
              class={[
                "py-2 border-b-2 text-sm font-medium",
                if(@active_tab == :provider, do: "border-indigo-500 text-indigo-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")
              ]}
              phx-click="select_settings_tab"
              phx-value-tab="provider"
            >
              AI Provider
            </button>
            <button
              class={[
                "py-2 border-b-2 text-sm font-medium",
                if(@active_tab == :events, do: "border-indigo-500 text-indigo-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")
              ]}
              phx-click="select_settings_tab"
              phx-value-tab="events"
            >
              Recent Events
            </button>
          </div>
        </div>

        <!-- Modal Body -->
        <div class="p-4 overflow-y-auto max-h-[60vh]">
          <%= if @active_tab == :visibility do %>
            <.visibility_tab game={@game} id_prefix={@id_prefix} />
          <% end %>

          <%= if @active_tab == :provider do %>
            <.provider_tab game={@game} id_prefix={@id_prefix} />
          <% end %>

          <%= if @active_tab == :events do %>
            <.events_tab rounds={@rounds} id_prefix={@id_prefix} />
          <% end %>
        </div>

        <!-- Modal Footer -->
        <div class="p-4 border-t border-gray-200 flex justify-end">
          <button
            class="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-800 rounded text-sm font-medium transition-colors"
            phx-click="toggle_settings_modal"
          >
            Close
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the visibility settings tab content.
  """
  attr :game, :map, required: true
  attr :id_prefix, :string, default: "settings"

  def visibility_tab(assigns) do
    ~H"""
    <div class="space-y-4">
      <h3 class="text-sm font-semibold text-gray-500">Game Visibility</h3>

      <div class="space-y-3">
        <div class="flex items-center justify-between">
          <div>
            <div class="font-medium">Public Game</div>
            <div class="text-sm text-gray-500">Allow others to view your game</div>
          </div>
          <div class="form-control">
            <input
              id={"#{@id_prefix}-public-toggle"}
              type="checkbox"
              checked={@game.is_public}
              phx-click="toggle_visibility"
              phx-value-field="is_public"
              class="toggle toggle-sm toggle-primary"
            />
          </div>
        </div>

        <div class="flex items-center justify-between">
          <div>
            <div class="font-medium">Leaderboard Eligible</div>
            <div class="text-sm text-gray-500">Allow your game to appear on leaderboards</div>
          </div>
          <div class="form-control">
            <input
              id={"#{@id_prefix}-leaderboard-toggle"}
              type="checkbox"
              checked={@game.is_leaderboard_eligible}
              phx-click="toggle_visibility"
              phx-value-field="is_leaderboard_eligible"
              class="toggle toggle-sm toggle-primary"
              disabled={!@game.is_public}
            />
          </div>
        </div>
      </div>

      <div class="text-xs text-gray-500 bg-gray-50 p-2 rounded">
        Public games can be viewed by others but only you can make decisions.
        Eligible games appear on the leaderboard when completed.
      </div>
    </div>
    """
  end

  @doc """
  Renders the AI provider selection tab content.
  """
  attr :game, :map, required: true
  attr :id_prefix, :string, default: "settings"

  def provider_tab(assigns) do
    ~H"""
    <div class="space-y-4">
      <h3 class="text-sm font-semibold text-gray-500">AI Provider Settings</h3>

      <div>
        <label for={"#{@id_prefix}-provider-select"} class="block text-sm font-medium text-gray-700">
          AI Provider
        </label>
        <select
          id={"#{@id_prefix}-provider-select"}
          phx-change="change_provider"
          class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
        >
          <option value="open_ai" selected={@game.provider_preference == :open_ai}>OpenAI</option>
          <option value="anthropic" selected={@game.provider_preference == :anthropic}>Anthropic</option>
          <option value="local" selected={@game.provider_preference == :local}>Local Model</option>
        </select>
        <p class="mt-2 text-sm text-gray-500">
          Select which AI provider to use for generating responses in your game.
          Different providers may have different capabilities and response styles.
        </p>
      </div>

      <div class="text-xs text-gray-500 bg-gray-50 p-2 rounded">
        Changing the AI provider will only affect future interactions in the game.
        Past interactions will remain unchanged.
      </div>
    </div>
    """
  end

  @doc """
  Renders the recent events tab content.
  """
  attr :rounds, :list, required: true
  attr :id_prefix, :string, default: "settings"

  def events_tab(assigns) do
    ~H"""
    <div class="space-y-4">
      <h3 class="text-sm font-semibold text-gray-500">Recent Events</h3>

      <div class="space-y-3">
        <%= if length(@rounds) > 0 do %>
          <%= for round <- Enum.take(Enum.reverse(@rounds), 5) do %>
            <div :if={round.situation} class="bg-gray-50 rounded-lg p-3">
              <div class="flex items-start">
                <div class="bg-blue-100 rounded-full p-1 mr-2 mt-0.5">
                  <.icon name="hero-star" class="h-3 w-3 text-blue-600" />
                </div>
                <div>
                  <div class="text-sm">
                    <%= round.situation %>
                  </div>
                  <div class="text-xs text-gray-500 mt-1">
                    <%= format_time(round.inserted_at) %>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        <% else %>
          <div class="text-sm text-gray-500 text-center py-4">
            No events yet. Start playing to see your game history.
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Helper functions

  @spec format_time(DateTime.t()) :: String.t()
  defp format_time(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y at %I:%M %p")
  end
end
