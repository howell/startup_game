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
  attr :player_mode, :atom, required: true # Added
  attr :game_state, :map, required: true # Added

  def chat_history(assigns) do
    assigns = assign(assigns, :last_round_index, length(assigns.rounds) - 1)

    ~H"""
    <div class="p-4 space-y-6">
      <%= for {round, index} <- Enum.with_index(@rounds) do %>
        <%!-- Conditionally render the situation for the last round based on player mode --%>
        <%= if index != @last_round_index or (@player_mode == :responding and @game_state.current_scenario_data) do %>
          <MessageBubble.message_bubble
            type={:system}
            content={round.situation}
            timestamp={round.inserted_at}
          />
        <% end %>

        <%!-- Render player input using the renamed field --%>
        <%= if round.player_input do %>
          <MessageBubble.message_bubble
            type={:user}
            content={round.player_input}
            timestamp={round.updated_at}
          />
        <% end %>

        <%!-- Render outcome as before --%>
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
