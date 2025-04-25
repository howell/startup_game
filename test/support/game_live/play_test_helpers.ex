defmodule StartupGameWeb.GameLive.Play.PlayTestHelpers do
  @moduledoc """
  Common helper functions for play LiveView tests.
  """

  import Phoenix.LiveViewTest

  @doc """
  Submits a response in the game's response form.
  """
  def submit_response(view, response) do
    view
    |> form("form[phx-submit='submit_response']", %{response: response})
    |> render_submit()
  end

  @doc """
  Creates a game by submitting name and description.
  """
  def create_game(view, name \\ "Acme Inc.", description \\ "A company that makes widgets") do
    submit_response(view, name)
    submit_response(view, description)
  end

  @doc """
  Selects acting mode for new game creation.
  """
  def select_acting_mode(view) do
    view
    |> element("input[phx-click='set_initial_mode'][phx-value-mode='acting']")
    |> render_click()
  end

  @doc """
  Extracts the game ID from a LiveView path.
  """
  def get_game_id_from_path(path), do: Path.basename(path)
end
