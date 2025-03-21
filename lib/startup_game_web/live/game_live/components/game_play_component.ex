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

  def game_play(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row gap-6">
      <!-- Chat area -->
      <div class="flex-grow order-2 md:order-1">
        <div class="bg-white rounded-lg shadow-md p-4 mb-4">
          <h1 class="text-2xl font-bold">{@game.name}</h1>
          <p class="text-gray-600">{@game.description}</p>
        </div>

        <ChatHistory.chat_history rounds={@rounds} />

        <%= if @game.status == :in_progress do %>
          <ResponseForm.response_form
            placeholder="How do you want to respond?"
            button_text="Send Response"
            value={@response}
          />
        <% else %>
          <div class="bg-white rounded-lg shadow-md p-4 text-center">
            <p class="text-xl font-semibold mb-3">
              Game {GameFormatters.game_end_status(@game)}
            </p>
            <p class="text-gray-600 mb-4">
              {GameFormatters.game_end_message(@game)}
            </p>
            <.link
              navigate={~p"/games"}
              class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-bold py-2 px-4 rounded"
            >
              Back to Games
            </.link>
          </div>
        <% end %>
      </div>
      
    <!-- Status panel -->
      <div class="w-full md:w-80 order-1 md:order-2">
        <div class="bg-white rounded-lg shadow-md p-4 mb-4">
          <h2 class="text-lg font-semibold mb-3">Company Finances</h2>

          <div class="space-y-4">
            <div>
              <p class="text-sm text-gray-500">Cash on Hand</p>
              <p class="text-2xl font-bold">
                ${GameFormatters.format_money(@game.cash_on_hand)}
              </p>
            </div>

            <div>
              <p class="text-sm text-gray-500">Monthly Burn Rate</p>
              <p class="text-xl font-semibold">
                ${GameFormatters.format_money(@game.burn_rate)}/month
              </p>
            </div>

            <div>
              <p class="text-sm text-gray-500">Runway</p>
              <p class="text-xl font-semibold">
                {GameFormatters.format_runway(Games.calculate_runway(@game))} months
              </p>
            </div>

            <%= if @game.exit_type in [:acquisition, :ipo] do %>
              <div>
                <p class="text-sm text-gray-500">Exit Value</p>
                <p class="text-2xl font-bold text-green-600">
                  ${GameFormatters.format_money(@game.exit_value)}
                </p>
              </div>
            <% end %>
          </div>
        </div>

        <ProviderSelector.provider_selector game={@game} />

        <div class="bg-white rounded-lg shadow-md p-4">
          <h2 class="text-lg font-semibold mb-3">Ownership Structure</h2>

          <div class="space-y-2">
            <%= for ownership <- @ownerships do %>
              <div class="flex justify-between items-center">
                <span>{ownership.entity_name}</span>
                <span class="font-semibold">
                  {GameFormatters.format_percentage(ownership.percentage)}%
                </span>
              </div>
              <div class="w-full bg-gray-200 rounded-full h-2">
                <div
                  class="bg-blue-600 h-2 rounded-full"
                  style={"width: #{Decimal.to_float(ownership.percentage)}%"}
                >
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
