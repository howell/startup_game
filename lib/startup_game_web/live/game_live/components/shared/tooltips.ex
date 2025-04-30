defmodule StartupGameWeb.GameLive.Components.Shared.Tooltips do
  @moduledoc """
  Tooltips for the game.
  """
  use StartupGameWeb, :html

  attr :id, :string, default: "take-the-wheel-tooltip"

  def take_the_wheel(assigns) do
    ~H"""
    <.info_tooltip
      id={@id}
      text="Steer the company any direction you want by describing your actions"
      position="top"
    />
    """
  end

  attr :id, :string, default: "release-the-wheel-tooltip"

  def release_the_wheel(assigns) do
    ~H"""
    <.info_tooltip id={@id} text="React to situations provided to you by AI" position="top" />
    """
  end
end
