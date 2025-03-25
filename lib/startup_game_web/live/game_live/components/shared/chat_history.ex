defmodule StartupGameWeb.GameLive.Components.Shared.ChatHistory do
  @moduledoc """
  Component for rendering the chat history with messages, responses, and outcomes.
  Also handles streaming content display.
  """
  use Phoenix.Component
  alias StartupGameWeb.GameLive.Components.Shared.MessageBubble

  @doc """
  Renders the chat history with messages, responses, and outcomes.
  Can also display streaming content in real-time.

  ## Examples

      <.chat_history rounds={@rounds} />
      <.chat_history rounds={@rounds} streaming={true} streaming_type={:scenario} partial_content="Loading..." />

  """
  attr :rounds, :list, required: true
  attr :streaming, :boolean, default: false
  attr :streaming_type, :atom, default: nil
  attr :partial_content, :string, default: ""

  def chat_history(assigns) do
    ~H"""
    <div class="p-4 space-y-6">
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

      <%= if @streaming and @partial_content != "" do %>
        <MessageBubble.message_bubble
          type={message_type_for_streaming(@streaming_type)}
          content={@partial_content}
          timestamp={DateTime.utc_now()}
          streaming={true}
        />
      <% end %>
      
    <!-- Adds some space at the bottom for better scrolling experience -->
      <div class="h-4"></div>
    </div>
    """
  end

  # Helper function to determine message type based on streaming type
  defp message_type_for_streaming(:scenario), do: :system
  defp message_type_for_streaming(:outcome), do: :outcome
  defp message_type_for_streaming(_), do: :system
end
