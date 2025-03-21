defmodule StartupGameWeb.GameLive.Components.Shared.MessageBubble do
  @moduledoc """
  Component for rendering chat message bubbles with different styles based on the message type.
  """
  use Phoenix.Component

  @doc """
  Renders a chat message bubble.

  ## Examples

      <.message_bubble
        type={:system}
        content="What would you like to name your company?"
        timestamp={~U[2023-01-01 12:00:00Z]}
      />

  """
  attr :type, :atom, required: true, values: [:system, :user, :outcome]
  attr :content, :string, required: true
  attr :timestamp, :any, required: true

  def message_bubble(assigns) do
    ~H"""
    <div class={container_class(@type)}>
      <div class={avatar_class(@type)}>
        <span class={avatar_text_class(@type)}><%= avatar_text(@type) %></span>
      </div>
      <div class={content_class(@type)}>
        <p class={bubble_class(@type)}>
          <%= @content %>
        </p>
        <p class="text-xs text-gray-500 mt-1">
          <%= Calendar.strftime(@timestamp, "%I:%M %p · %b %d") %>
        </p>
      </div>
    </div>
    """
  end

  # Helper functions for styling
  defp container_class(:user), do: "flex items-start gap-3 justify-end"
  defp container_class(_), do: "flex items-start gap-3"

  defp avatar_class(_), do: "w-10 h-10 rounded-full flex items-center justify-center"

  defp avatar_text_class(:system), do: "text-blue-600 font-semibold"
  defp avatar_text_class(:user), do: "text-green-600 font-semibold"
  defp avatar_text_class(:outcome), do: "text-blue-600 font-semibold"

  defp avatar_text(:system), do: "CF"
  defp avatar_text(:user), do: "ME"
  defp avatar_text(:outcome), do: "CF"

  defp content_class(:user), do: "flex-1 text-right"
  defp content_class(_), do: "flex-1"

  defp bubble_class(:system), do: "bg-blue-100 p-3 rounded-lg rounded-tl-none"
  defp bubble_class(:user), do: "bg-green-100 p-3 rounded-lg rounded-tr-none inline-block text-left"
  defp bubble_class(:outcome), do: "bg-gray-100 p-3 rounded-lg rounded-tl-none"
end
