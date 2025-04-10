defmodule StartupGameWeb.Admin.TrainingGameLive.Index do
  use StartupGameWeb, :live_view

  alias StartupGame.Games
  alias StartupGameWeb.Admin.TrainingGameLive.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:training_games, Games.list_training_games())
      |> assign(:show_create_modal, false)
      |> assign(:show_import_modal, false)

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

    <.modal :if={@show_create_modal} id="create-game-modal" show on_cancel={JS.push("close_modal")}>
      <.live_component
        module={FormComponent}
        id="create-game-component"
        title="Create New Training Game"
        live_action={:new}
        current_user={@current_user}
        parent_pid={self()}
        # Pass other necessary assigns if any
      />
    </.modal>

    <.modal :if={@show_import_modal} id="import-game-modal" show on_cancel={JS.push("close_modal")}>
      <%# TODO: Implement Import Game Component/UI %>
      <h2 class="text-lg font-semibold mb-4">Import Existing Game</h2>
      <p>Import functionality will be implemented here.</p>
      <.button type="button" phx-click="close_modal" class="mt-4">Cancel</.button>
    </.modal>
    """
  end

  # TODO: Add event handlers for create_game and import_game

  @impl true
  def handle_event("create_game", _, socket) do
    {:noreply, assign(socket, :show_create_modal, true)}
  end

  def handle_event("import_game", _, socket) do
    # TODO: Fetch non-training games to pass to the modal/component
    {:noreply, assign(socket, :show_import_modal, true)}
  end

  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, show_create_modal: false, show_import_modal: false)}
  end

  # TODO: Add handler for import_game

  @impl true
  def handle_info({:close_game_form}, socket) do
    # Message sent from FormComponent on cancel
    # Can potentially be reused if import form sends the same message
    {:noreply, assign(socket, show_create_modal: false, show_import_modal: false)}
  end

  def handle_info({:saved_game, _game}, socket) do
    # Message sent from FormComponent on successful save
    # Close modal and refresh game list
    {:noreply,
     socket
     |> put_flash(:info, "Training game created successfully.")
     |> assign(:show_create_modal, false)
     |> assign(:training_games, Games.list_training_games())}
  end
end
