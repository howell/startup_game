defmodule StartupGameWeb.GameLive.Components.Shared.ChatHistory do
  @moduledoc """
  Component for rendering the chat history with messages, responses, and outcomes.
  """
  use Phoenix.Component
  alias StartupGameWeb.GameLive.Components.Shared.MessageBubble

  @doc """
  Renders the chat history with messages, responses, and outcomes.

  ## Examples

      <.chat_history rounds={@rounds} />

  """
  attr :rounds, :list, required: true

  def chat_history(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-md p-4 mb-4 h-[60vh] overflow-y-auto" id="chat-messages">
      <div class="space-y-6">
        <%= for round <- @rounds do %>
          <MessageBubble.message_bubble
            type={:system}
            content={round.situation}
            timestamp={round.inserted_at}
          />

          <%= if round.response do %>
            <MessageBubble.message_bubble
              type={:user}
              content={round.response}
              timestamp={round.updated_at}
            />
          <% end %>

          <%= if round.outcome do %>
            <MessageBubble.message_bubble
              type={:outcome}
              content={round.outcome}
              timestamp={round.updated_at}
            />
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
