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
    <div class="h-full flex flex-col">
      <!-- Chat messages with scrolling -->
      <div class="flex-1 overflow-y-auto" id="chat-messages">
        <ChatHistory.chat_history
          rounds={@rounds}
          streaming={@streaming}
          streaming_type={@streaming_type}
          partial_content={@partial_content}
        />
      </div>

      <%= if @game.status == :in_progress do %>
        <!-- Response form at bottom -->
        <div class="mt-4 p-4 border-t">
          <div class="mx-auto w-full">
            <ResponseForm.response_form
              placeholder="How do you want to respond?"
              button_text="Send Response"
              value={@response}
              disabled={@streaming}
            />
          </div>
        </div>
      <% else %>
        <.game_end_message game={@game} />
      <% end %>
    </div>
    """
  end

  attr :game, :map, required: true

  defp chat_header(assigns) do
    ~H"""
    <div class="p-4 border-b">
      <h2 class="heading-sm">{@game.name}</h2>
      <p class="text-sm text-foreground/70">{@game.description}</p>
    </div>
    """
  end

  attr :game, :map, required: true

  defp game_end_message(assigns) do
    ~H"""
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
    """
  end
end
