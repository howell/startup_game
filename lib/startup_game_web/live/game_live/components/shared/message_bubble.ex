defmodule StartupGameWeb.GameLive.Components.Shared.MessageBubble do
  @moduledoc """
  Component for rendering chat message bubbles with different styles based on the message type.
  """
  use StartupGameWeb, :html

  @doc """
  Renders a chat message bubble.

  ## Examples

      <.message_bubble
        type={:system}
        content="What would you like to name your company?"
        timestamp={~U[2023-01-01 12:00:00Z]}
      />

      <.message_bubble
        type={:system}
        content="Loading..."
        timestamp={~U[2023-01-01 12:00:00Z]}
        streaming={true}
      />

  """
  attr :type, :atom, required: true, values: [:system, :user, :outcome]
  attr :content, :string, required: true
  attr :timestamp, :any, required: true
  attr :streaming, :boolean, default: false

  def message_bubble(assigns) do
    ~H"""
    <div class={container_class(@type)}>
      <div class={avatar_class(@type)}>
        <.icon name={avatar_icon(@type)} class={avatar_icon_class(@type)} />
      </div>
      <div class={content_class(@type)}>
        <div class={bubble_class(@type, @streaming)}>
          <p class="whitespace-pre-wrap">{@content}</p>
          <.ellipsis :if={@streaming} />
        </div>
        <p class="text-xs text-foreground/60 mt-1">
          {Calendar.strftime(@timestamp, "%I:%M %p · %b %d")}
        </p>
      </div>
    </div>
    """
  end

  # Helper functions for styling
  defp container_class(:user), do: "flex items-start gap-3 justify-end"
  defp container_class(_), do: "flex items-start gap-3"

  defp avatar_class(:system),
    do: "w-10 h-10 bg-silly-blue/10 rounded-full flex items-center justify-center"

  defp avatar_class(:user),
    do: "w-10 h-10 bg-silly-accent/10 rounded-full flex items-center justify-center"

  defp avatar_class(:outcome),
    do: "w-10 h-10 bg-silly-purple/10 rounded-full flex items-center justify-center"

  defp avatar_icon(:system), do: "hero-computer-desktop"
  defp avatar_icon(:user), do: "hero-user"
  defp avatar_icon(:outcome), do: "hero-sparkles"

  defp avatar_icon_class(:system), do: "h-5 w-5 text-silly-blue"
  defp avatar_icon_class(:user), do: "h-5 w-5 text-silly-accent"
  defp avatar_icon_class(:outcome), do: "h-5 w-5 text-silly-purple"

  defp content_class(:user), do: "flex-1 text-right"
  defp content_class(_), do: "flex-1"

  defp bubble_class(:system, streaming?) do
    base =
      "bg-white/90 backdrop-blur-sm p-4 rounded-lg rounded-tl-none border border-gray-200/50 shadow-sm"

    if streaming?, do: "#{base} animate-pulse", else: base
  end

  defp bubble_class(:user, streaming?) do
    base = "bg-silly-blue text-white p-4 rounded-lg rounded-tr-none inline-block text-left"
    if streaming?, do: "#{base} animate-pulse", else: base
  end

  defp bubble_class(:outcome, streaming?) do
    base = "bg-silly-purple/10 p-4 rounded-lg rounded-tl-none border border-silly-purple/20"
    if streaming?, do: "#{base} animate-pulse", else: base
  end

  defp ellipsis(assigns) do
    ~H"""
    <div class="flex mt-2 space-x-1">
      <div class="h-2 w-2 bg-gray-400 rounded-full animate-bounce"></div>
      <div class="h-2 w-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0.2s">
      </div>
      <div class="h-2 w-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0.4s">
      </div>
    </div>
    """
  end
end
