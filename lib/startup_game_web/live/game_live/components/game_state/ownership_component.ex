defmodule StartupGameWeb.GameLive.Components.GameState.OwnershipComponent do
  @moduledoc """
  Component for rendering the ownership structure section with percentage bars.
  """
  use StartupGameWeb, :html

  alias StartupGameWeb.GameLive.Helpers.GameFormatters

  @doc """
  Renders the ownership structure section with title and percentage bars
  """
  attr :ownerships, :list, required: true

  def ownership_section(assigns) do
    ~H"""
    <div>
      <h3 class="text-sm font-semibold text-foreground/70 mb-3">OWNERSHIP STRUCTURE</h3>
      <div class="space-y-3">
        <%= for ownership <- @ownerships do %>
          <.ownership_bar ownership={ownership} />
        <% end %>
      </div>
    </div>
    """
  end

  attr :ownership, :map, required: true

  defp ownership_bar(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between text-sm mb-1">
        <span><%= @ownership.entity_name %></span>
        <span class="font-medium">
          <%= GameFormatters.format_percentage(@ownership.percentage) %>%
        </span>
      </div>
      <div class="h-2 bg-gray-200 rounded-full overflow-hidden">
        <div
          class="h-full bg-silly-blue rounded-full"
          style={"width: #{Decimal.to_float(@ownership.percentage)}%"}
        >
        </div>
      </div>
    </div>
    """
  end
end
