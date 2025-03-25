defmodule StartupGameWeb.GameLive.Components.Chat.ChatInterfaceComponent do
  @moduledoc """
  Component for rendering the chat interface with header, messages, and response form.
  """
  use StartupGameWeb, :html

  alias StartupGameWeb.GameLive.Components.Shared.ChatHistory
  alias StartupGameWeb.GameLive.Components.Shared.ResponseForm
  alias StartupGameWeb.GameLive.Helpers.GameFormatters

  @doc """
  Renders the chat interface with header, messages, and response form or game end message
  """
  attr :game, :map, required: true
  attr :rounds, :list, required: true
  attr :response, :string, default: ""
  attr :streaming, :boolean, default: false
  attr :streaming_type, :atom, default: nil
  attr :partial_content, :string, default: ""

  def chat_interface(assigns) do
    ~H"""
    <div class="flex-1 order-2 lg:order-1">
      <div class="glass-card h-full flex flex-col">
        <.chat_header game={@game} />

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
          <.game_end_message game={@game} />
        <% end %>
      </div>
    </div>
    """
  end

  attr :game, :map, required: true

  defp chat_header(assigns) do
    ~H"""
    <div class="p-4 border-b">
      <h2 class="heading-sm"><%= @game.name %></h2>
      <p class="text-sm text-foreground/70"><%= @game.description %></p>
    </div>
    """
  end

  attr :game, :map, required: true

  defp game_end_message(assigns) do
    ~H"""
    <div class="p-4 border-t text-center">
      <p class="text-xl font-semibold mb-3">
        Game <%= GameFormatters.game_end_status(@game) %>
      </p>
      <p class="text-gray-600 mb-4">
        <%= GameFormatters.game_end_message(@game) %>
      </p>
      <.link navigate={~p"/games"} class="silly-button-primary">
        Back to Games
      </.link>
    </div>
    """
  end
end
