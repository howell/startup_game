defmodule StartupGameWeb.GameLive.Components.Shared.ChatHistory do
  @moduledoc """
  Component for rendering the chat history with messages, responses, and outcomes.
  Also handles streaming content display.
  """
  use Phoenix.Component
  alias StartupGameWeb.GameLive.Components.Shared.MessageBubble
  alias StartupGameWeb.GameLive.Components.Shared.Icons
  alias StartupGameWeb.GameLive.Helpers.GameFormatters

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
  attr :player_mode, :atom, required: true

  def chat_history(assigns) do
    assigns = assign(assigns, :last_round_index, length(assigns.rounds) - 1)

    ~H"""
    <div>
      <div class="p-4 space-y-6" id="chat-history" phx-update="stream">
        <%= for {round, _index} <- Enum.with_index(@rounds) do %>
          <span id={round.id}>
            <MessageBubble.message_bubble
              :if={round.situation}
              type={:system}
              content={round.situation}
              timestamp={round.inserted_at}
            />

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
            <.round_state_changes round={round} />
          </span>
        <% end %>
      </div>

      <%= if @streaming and @partial_content != "" do %>
        <MessageBubble.message_bubble
          type={message_type_for_streaming(@streaming_type)}
          content={@partial_content}
          timestamp={DateTime.utc_now()}
          streaming={true}
        />
      <% end %>
      
    <!-- Adds some space at the bottom for better scrolling experience -->
      <div class="h-4" id="chat-history-end"></div>
    </div>
    """
  end

  # Helper function to determine message type based on streaming type
  defp message_type_for_streaming(:scenario), do: :system
  defp message_type_for_streaming(:outcome), do: :outcome
  defp message_type_for_streaming(_), do: :system

  # Renders the state changes that occurred during a round.
  attr :round, :map, required: true

  defp round_state_changes(assigns) do
    round = assigns.round
    cash_change = format_change(round.cash_change, "Cash", :cash)

    burn_rate_change =
      format_change(round.burn_rate_change, "Burn Rate", :burn, "/mo")

    ownership_changes = if is_list(round.ownership_changes), do: round.ownership_changes, else: []

    has_changes? =
      !is_nil(cash_change) || !is_nil(burn_rate_change) || !Enum.empty?(ownership_changes)

    assigns =
      assign(assigns,
        cash_change: cash_change,
        burn_rate_change: burn_rate_change,
        ownership_changes: ownership_changes,
        has_changes?: has_changes?
      )

    render_round_state_changes(assigns)
  end

  defp render_round_state_changes(assigns) do
    ~H"""
    <div
      :if={@has_changes?}
      class="ml-12 mt-2 mb-4 text-sm text-foreground/70 flex flex-col md:flex-row md:items-center gap-4"
    >
      <%= if @cash_change do %>
        <div class="flex items-center">
          <Icons.icon_by_type icon_type={elem(@cash_change, 0)} size={:xs} />
          <span class="ml-1">{elem(@cash_change, 1)}</span>
        </div>
      <% end %>
      <%= if @burn_rate_change do %>
        <div class="flex items-center">
          <Icons.icon_by_type icon_type={elem(@burn_rate_change, 0)} size={:xs} />
          <span class="ml-1">{elem(@burn_rate_change, 1)}</span>
        </div>
      <% end %>
      <%= for change <- @ownership_changes do %>
        <div class="flex items-center">
          <Icons.user_add_icon size={:xs} />
          <span class="ml-1">
            {change.entity_name}:
            <.ownership_change_icon delta={change.percentage_delta} /> {format_percentage_delta(
              change.percentage_delta
            )}
          </span>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper to format a numeric change with prefix, icon, and suffix
  defp format_change(value, label, icon_type, suffix \\ "") do
    if value && !Decimal.equal?(value, Decimal.new(0)) do
      prefix = if Decimal.gt?(value, 0), do: "+", else: ""
      formatted_value = GameFormatters.format_money(value)
      {icon_type, "#{label}: #{prefix}#{formatted_value}#{suffix}"}
    else
      nil
    end
  end

  # Format percentage delta with + or - sign
  defp format_percentage_delta(delta) do
    prefix = if Decimal.positive?(delta), do: "+", else: ""
    "#{prefix}#{Decimal.to_string(delta, :xsd)}%"
  end

  defp ownership_change_icon(assigns) do
    ~H"""
    <%= if Decimal.positive?(@delta) do %>
      <Icons.uptrend_icon size={:xs} />
    <% else %>
      <Icons.downtrend_icon size={:xs} />
    <% end %>
    """
  end
end
