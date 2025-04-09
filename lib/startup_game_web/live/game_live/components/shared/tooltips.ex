defmodule StartupGameWeb.GameLive.Components.Shared.Tooltips do
  @moduledoc """
  Tooltips for the game.
  """
  use StartupGameWeb, :html

  def take_the_wheel(assigns) do
    ~H"""
    <.info_tooltip
      id="take-the-wheel-tooltip"
      text="Steer the company any direction you want by describing your actions"
      position="top"
    />
    """
  end

  def release_the_wheel(assigns) do
    ~H"""
    <.info_tooltip
      id="release-the-wheel-tooltip"
      text="React to situations provided to you by AI"
      position="top"
    />
    """
  end
end
