defmodule StartupGameWeb.Components.Home.FeatureCard do
  @moduledoc """
  Feature card component for displaying features throughout the home page.

  A reusable card with an icon, title, and description. The icon color is customizable
  and automatically applies appropriate background color based on the selected color theme.
  Used primarily in the "How It Works" section.
  """
  use StartupGameWeb, :html

  attr :icon, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :icon_color, :string, default: "text-silly-purple"
  attr :class, :string, default: ""

  def feature_card(assigns) do
    ~H"""
    <div class={"silly-card group #{@class}"}>
      <div class={get_icon_bg_class(@icon_color)}>
        <.icon name={@icon} class={"transition-all duration-300 #{@icon_color}"} />
      </div>
      <h3 class="heading-sm mb-2">{@title}</h3>
      <p class="text-foreground/70">{@description}</p>
    </div>
    """
  end

  defp get_icon_bg_class(icon_color) do
    base_class =
      "mb-4 inline-flex items-center justify-center w-12 h-12 rounded-full transition-all duration-300 group-hover:scale-110"

    bg_class =
      case icon_color do
        "text-silly-purple" -> "bg-silly-purple/10"
        "text-silly-blue" -> "bg-silly-blue/10"
        "text-silly-accent" -> "bg-silly-accent/10"
        "text-silly-yellow" -> "bg-silly-yellow/10"
        _ -> "bg-gray-100"
      end

    "#{base_class} #{bg_class}"
  end
end
