defmodule StartupGameWeb.Admin.TrainingGameLive.Index do
  use StartupGameWeb, :live_view

  alias StartupGame.Games

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :training_games, Games.list_training_games())

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Training Games")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Training Games
      <:actions>
        <.button phx-click="create_game">Create New Training Game</.button>
        <.button phx-click="import_game">Import Existing Game</.button>
      </:actions>
    </.header>

    <.table id="training-games" rows={@training_games}>
      <:col :let={game} label="Name">{game.name}</:col>
      <:col :let={game} label="Status">{game.status}</:col>
      <:col :let={game} label="Created">{game.inserted_at}</:col>
      <:action :let={game}>
        <.link navigate={"/admin/training_games/#{game.id}/play"}>Play/Edit</.link>
      </:action>
    </.table>
    <% # TODO: Add modals/components for create and import %>
    """
  end

  # TODO: Add event handlers for create_game and import_game
end
