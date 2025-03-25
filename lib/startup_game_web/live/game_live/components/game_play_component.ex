defmodule StartupGameWeb.GameLive.Components.GamePlayComponent do
  @moduledoc """
  Component for rendering the game play interface with chat, company info, and financials.
  """
  use StartupGameWeb, :html
  alias StartupGameWeb.GameLive.Components.Shared.ChatHistory
  alias StartupGameWeb.GameLive.Components.Shared.ResponseForm
  alias StartupGameWeb.GameLive.Components.Shared.ProviderSelector
  alias StartupGameWeb.GameLive.Helpers.GameFormatters
  alias StartupGame.Games

  @doc """
  Renders the game play interface with chat, company info, and financials.
  """
  attr :game, :map, required: true
  attr :game_state, :map, required: true
  attr :rounds, :list, required: true
  attr :ownerships, :list, required: true
  attr :response, :string, default: ""
  attr :streaming, :boolean, default: false
  attr :partial_content, :string, default: ""
  attr :streaming_type, :atom, default: nil
  attr :is_mobile_state_visible, :boolean, default: false

  def game_play(assigns) do
    ~H"""
    <div class="flex flex-col lg:flex-row gap-6 h-dvh">
      <!-- Mobile toggle for game state -->
      <button
        class="lg:hidden silly-button-secondary mb-4 flex items-center justify-center"
        phx-click="toggle_mobile_state"
      >
        {if @is_mobile_state_visible, do: "Hide Game State", else: "Show Game State"}
      </button>

    <!-- Game state panel - hidden on mobile unless toggled -->
      <div class={"#{if @is_mobile_state_visible, do: "block", else: "hidden"} lg:block lg:w-1/3 xl:w-1/4 order-1 lg:order-2"}>
        <div class="h-fit overflow-y-auto">
          <div class="glass-card h-full p-5">
            <!-- Company header -->
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

            <div class="space-y-6">
              <!-- Company metrics section -->
              <div>
                <h3 class="text-sm font-semibold text-foreground/70 mb-3">COMPANY FINANCES</h3>
                <div class="grid grid-cols-2 gap-3">
                  <div class="silly-stat-card">
                    <.icon name="hero-currency-dollar" class="text-silly-success" />
                    <div>
                      <div class="font-bold">${GameFormatters.format_money(@game.cash_on_hand)}</div>
                      <div class="text-xs text-foreground/70">Cash</div>
                    </div>
                  </div>

                  <div class="silly-stat-card">
                    <.icon name="hero-arrow-trending-down" class="text-silly-accent" />
                    <div>
                      <div class="font-bold">${GameFormatters.format_money(@game.burn_rate)}/mo</div>
                      <div class="text-xs text-foreground/70">Burn Rate</div>
                    </div>
                  </div>

                  <div class="silly-stat-card">
                    <.icon name="hero-exclamation-triangle" class="text-silly-yellow" />
                    <div>
                      <div class="font-bold">
                        {GameFormatters.format_runway(Games.calculate_runway(@game))}
                      </div>
                      <div class="text-xs text-foreground/70">Runway (months)</div>
                    </div>
                  </div>

                  <%= if @game.exit_type in [:acquisition, :ipo] do %>
                    <div class="silly-stat-card">
                      <.icon name="hero-trophy" class="text-silly-success" />
                      <div>
                        <div class="font-bold">${GameFormatters.format_money(@game.exit_value)}</div>
                        <div class="text-xs text-foreground/70">Exit Value</div>
                      </div>
                    </div>
                  <% else %>
                    <div class="silly-stat-card">
                      <.icon name="hero-building-office-2" class="text-silly-blue" />
                      <div>
                        <div class="font-bold">{length(@ownerships)}</div>
                        <div class="text-xs text-foreground/70">Stakeholders</div>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>

    <!-- Ownership Structure section -->
              <div>
                <h3 class="text-sm font-semibold text-foreground/70 mb-3">OWNERSHIP STRUCTURE</h3>

                <div class="space-y-3">
                  <%= for ownership <- @ownerships do %>
                    <div>
                      <div class="flex justify-between text-sm mb-1">
                        <span>{ownership.entity_name}</span>
                        <span class="font-medium">
                          {GameFormatters.format_percentage(ownership.percentage)}%
                        </span>
                      </div>
                      <div class="h-2 bg-gray-200 rounded-full overflow-hidden">
                        <div
                          class="h-full bg-silly-blue rounded-full"
                          style={"width: #{Decimal.to_float(ownership.percentage)}%"}
                        >
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>

    <!-- Provider selector -->
              <ProviderSelector.provider_selector game={@game} />

    <!-- Recent events section -->
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
            </div>
          </div>
        </div>
      </div>

    <!-- Chat interface -->
      <div class="flex-1 order-2 lg:order-1">
        <div class="glass-card h-full flex flex-col">
          <div class="p-4 border-b">
            <h2 class="heading-sm">{@game.name}</h2>
            <p class="text-sm text-foreground/70">{@game.description}</p>
          </div>

          <div
            class="flex-1 border border-gray-200 overflow-y-auto"
            id="chat-messages"
            phx-hook="ScrollToBottom"
          >
            <ChatHistory.chat_history
              rounds={@rounds}
              streaming={@streaming}
              streaming_type={@streaming_type}
              partial_content={@partial_content}
            />
          </div>

          <%= if @game.status == :in_progress do %>
            <div class="p-4 border-t">
              <ResponseForm.response_form
                placeholder="How do you want to respond?"
                button_text="Send Response"
                value={@response}
                disabled={@streaming}
              />
              <div class="mt-2 flex justify-between items-center text-xs text-foreground/60">
                <span>Press Enter to send</span>
                <.link navigate={~p"/games"} class="flex items-center gap-1 hover:text-foreground/80">
                  <.icon name="hero-home" class="h-3 w-3" /> Back to Games
                </.link>
              </div>
            </div>
          <% else %>
            <div class="p-4 border-t text-center">
              <p class="text-xl font-semibold mb-3">
                Game {GameFormatters.game_end_status(@game)}
              </p>
              <p class="text-gray-600 mb-4">
                {GameFormatters.game_end_message(@game)}
              </p>
              <.link navigate={~p"/games"} class="silly-button-primary">
                Back to Games
              </.link>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
