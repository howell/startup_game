defmodule StartupGameWeb.GameLive.Components.Shared.Icons do
  @moduledoc """
  Centralized icon definitions for consistent styling across the application.

  This module provides standardized icons with customizable sizes and colors
  to ensure consistency across the UI. Icons can be used across different
  components without repeating styling code.
  """
  use StartupGameWeb, :html

  alias StartupGameWeb.CoreComponents

  @doc """
  Renders an icon based on the provided icon type.

  ## Attributes
    * `icon_type` - Atom representing the icon type to render (e.g., :cash, :burn, :runway)
    * `class` - Additional CSS classes (optional)
    * `size` - Icon size: :xs, :sm, :md, :lg (default: :md)

  ## Examples

      <Icons.icon_by_type icon_type={:cash} size={:sm} />
  """
  attr :icon_type, :atom, required: true
  attr :class, :string, default: ""
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg]

  def icon_by_type(assigns) do
    ~H"""
    <%= case @icon_type do %>
      <% :cash -> %>
        <.cash_icon size={@size} class={@class} />
      <% :burn -> %>
        <.burn_icon size={@size} class={@class} />
      <% :runway -> %>
        <.runway_icon size={@size} class={@class} />
      <% :founder -> %>
        <.founder_icon size={@size} class={@class} />
      <% :stakeholder -> %>
        <.stakeholder_icon size={@size} class={@class} />
      <% :uptrend -> %>
        <.uptrend_icon size={@size} class={@class} />
      <% :trophy -> %>
        <.trophy_icon size={@size} class={@class} />
      <% :user_add -> %>
        <.user_add_icon size={@size} class={@class} />
      <% :settings -> %>
        <.settings_icon size={@size} class={@class} />
      <% :star -> %>
        <.star_icon size={@size} class={@class} />
      <% :chevron_up -> %>
        <.chevron_up_icon size={@size} class={@class} />
      <% :chevron_down -> %>
        <.chevron_down_icon size={@size} class={@class} />
      <% _ -> %>
        <CoreComponents.icon
          name="hero-question-mark-circle"
          class={Enum.join([get_size_class(@size), @class], " ")}
        />
    <% end %>
    """
  end

  @doc """
  Renders a cash/money icon.

  ## Attributes
    * `class` - Additional CSS classes (optional)
    * `size` - Icon size: :xs, :sm, :md, :lg (default: :md)
  """
  attr :class, :string, default: ""
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg]

  def cash_icon(assigns) do
    assigns = assign(assigns, :base_class, "text-silly-success")

    ~H"""
    <CoreComponents.icon
      name="hero-currency-dollar"
      class={Enum.join([get_size_class(@size), @base_class, @class], " ")}
    />
    """
  end

  @doc """
  Renders a burn rate icon.

  ## Attributes
    * `class` - Additional CSS classes (optional)
    * `size` - Icon size: :xs, :sm, :md, :lg (default: :md)
  """
  attr :class, :string, default: ""
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg]

  def burn_icon(assigns) do
    assigns = assign(assigns, :base_class, "text-silly-accent")

    ~H"""
    <CoreComponents.icon
      name="hero-fire"
      class={Enum.join([get_size_class(@size), @base_class, @class], " ")}
    />
    """
  end

  @doc """
  Renders a runway/warning icon.

  ## Attributes
    * `class` - Additional CSS classes (optional)
    * `size` - Icon size: :xs, :sm, :md, :lg (default: :md)
  """
  attr :class, :string, default: ""
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg]

  def runway_icon(assigns) do
    assigns = assign(assigns, :base_class, "text-silly-yellow")

    ~H"""
    <CoreComponents.icon
      name="hero-clock"
      class={Enum.join([get_size_class(@size), @base_class, @class], " ")}
    />
    """
  end

  @doc """
  Renders a founder icon.

  ## Attributes
    * `class` - Additional CSS classes (optional)
    * `size` - Icon size: :xs, :sm, :md, :lg (default: :md)
  """
  attr :class, :string, default: ""
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg]

  def founder_icon(assigns) do
    assigns = assign(assigns, :base_class, "text-silly-blue")

    ~H"""
    <CoreComponents.icon
      name="hero-users-mini"
      class={Enum.join([get_size_class(@size), @base_class, @class], " ")}
    />
    """
  end

  @doc """
  Renders an investor/stakeholder icon.

  ## Attributes
    * `class` - Additional CSS classes (optional)
    * `size` - Icon size: :xs, :sm, :md, :lg (default: :md)
  """
  attr :class, :string, default: ""
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg]

  def stakeholder_icon(assigns) do
    assigns = assign(assigns, :base_class, "text-silly-blue")

    ~H"""
    <CoreComponents.icon
      name="hero-building-office-2"
      class={Enum.join([get_size_class(@size), @base_class, @class], " ")}
    />
    """
  end

  @doc """
  Renders an uptrend icon.

  ## Attributes
    * `class` - Additional CSS classes (optional)
    * `size` - Icon size: :xs, :sm, :md, :lg (default: :md)
  """
  attr :class, :string, default: ""
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg]

  def uptrend_icon(assigns) do
    assigns = assign(assigns, :base_class, "text-silly-success")

    ~H"""
    <CoreComponents.icon
      name="hero-arrow-trending-up"
      class={Enum.join([get_size_class(@size), @base_class, @class], " ")}
    />
    """
  end

  @doc """
  Renders a downtrend icon.

  ## Attributes
    * `class` - Additional CSS classes (optional)
    * `size` - Icon size: :xs, :sm, :md, :lg (default: :md)
  """
  attr :class, :string, default: ""
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg]

  def downtrend_icon(assigns) do
    assigns = assign(assigns, :base_class, "text-silly-danger")

    ~H"""
    <CoreComponents.icon
      name="hero-arrow-trending-down"
      class={Enum.join([get_size_class(@size), @base_class, @class], " ")}
    />
    """
  end

  @doc """
  Renders a trophy/success icon.

  ## Attributes
    * `class` - Additional CSS classes (optional)
    * `size` - Icon size: :xs, :sm, :md, :lg (default: :md)
  """
  attr :class, :string, default: ""
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg]

  def trophy_icon(assigns) do
    assigns = assign(assigns, :base_class, "text-silly-success")

    ~H"""
    <CoreComponents.icon
      name="hero-trophy"
      class={Enum.join([get_size_class(@size), @base_class, @class], " ")}
    />
    """
  end

  @doc """
  Renders a user addition icon.

  ## Attributes
    * `class` - Additional CSS classes (optional)
    * `size` - Icon size: :xs, :sm, :md, :lg (default: :md)
  """
  attr :class, :string, default: ""
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg]

  def user_add_icon(assigns) do
    assigns = assign(assigns, :base_class, "text-silly-blue")

    ~H"""
    <CoreComponents.icon
      name="hero-user-plus"
      class={Enum.join([get_size_class(@size), @base_class, @class], " ")}
    />
    """
  end

  @doc """
  Renders a settings icon.

  ## Attributes
    * `class` - Additional CSS classes (optional)
    * `size` - Icon size: :xs, :sm, :md, :lg (default: :md)
  """
  attr :class, :string, default: ""
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg]

  def settings_icon(assigns) do
    assigns = assign(assigns, :base_class, "")

    ~H"""
    <CoreComponents.icon
      name="hero-cog-6-tooth-mini"
      class={Enum.join([get_size_class(@size), @base_class, @class], " ")}
    />
    """
  end

  @doc """
  Renders a star icon.

  ## Attributes
    * `class` - Additional CSS classes (optional)
    * `size` - Icon size: :xs, :sm, :md, :lg (default: :md)
  """
  attr :class, :string, default: ""
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg]

  def star_icon(assigns) do
    assigns = assign(assigns, :base_class, "text-silly-blue")

    ~H"""
    <CoreComponents.icon
      name="hero-star"
      class={Enum.join([get_size_class(@size), @base_class, @class], " ")}
    />
    """
  end

  @doc """
  Renders a chevron up icon.

  ## Attributes
    * `class` - Additional CSS classes (optional)
    * `size` - Icon size: :xs, :sm, :md, :lg (default: :md)
  """
  attr :class, :string, default: ""
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg]

  def chevron_up_icon(assigns) do
    assigns = assign(assigns, :base_class, "text-gray-500")

    ~H"""
    <CoreComponents.icon
      name="hero-chevron-up-mini"
      class={Enum.join([get_size_class(@size), @base_class, @class], " ")}
    />
    """
  end

  @doc """
  Renders a chevron down icon.

  ## Attributes
    * `class` - Additional CSS classes (optional)
    * `size` - Icon size: :xs, :sm, :md, :lg (default: :md)
  """
  attr :class, :string, default: ""
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg]

  def chevron_down_icon(assigns) do
    assigns = assign(assigns, :base_class, "text-gray-500")

    ~H"""
    <CoreComponents.icon
      name="hero-chevron-down-mini"
      class={Enum.join([get_size_class(@size), @base_class, @class], " ")}
    />
    """
  end

  # Private helper to get the size class based on the size atom
  defp get_size_class(:xs), do: "w-3 h-3"
  defp get_size_class(:sm), do: "w-4 h-4"
  defp get_size_class(:md), do: "w-5 h-5"
  defp get_size_class(:lg), do: "w-6 h-6"
end
