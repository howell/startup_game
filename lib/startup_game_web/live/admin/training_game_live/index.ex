defmodule StartupGameWeb.Admin.TrainingGameLive.Index do
  use StartupGameWeb, :live_view

  alias StartupGame.Games
  alias StartupGameWeb.Admin.TrainingGameLive.FormComponent
  alias StartupGame.Games.Game

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:training_games, Games.list_training_games())
      |> assign(:show_create_modal, false)
      |> assign(:show_import_modal, false)
      |> assign(:importable_games, [])

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
      />
    </.modal>

    <.modal :if={@show_import_modal} id="import-game-modal" show on_cancel={JS.push("close_modal")}>
      <h2 class="text-lg font-semibold mb-4">Import Existing Game</h2>
      <form phx-submit="confirm_import">
        <label for="import-game-select" class="block text-sm font-medium text-gray-700">
          Select game to import:
        </label>
        <select
          id="import-game-select"
          name="source_game_id"
          class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
        >
          <option value="">-- Select a Game --</option>
          <option :for={game <- @importable_games} value={game.id}>
            {game.name} (User: {game.user_id}, Status: {game.status})
          </option>
        </select>

        <div class="mt-6 flex justify-end gap-3">
          <.button type="button" phx-click="close_modal">Cancel</.button>
          <.button type="submit" phx-disable-with="Importing...">Confirm Import</.button>
        </div>
      </form>
    </.modal>
    """
  end

  # TODO: Add event handlers for create_game and import_game

  @impl true
  def handle_event("create_game", _, socket) do
    {:noreply, assign(socket, :show_create_modal, true)}
  end

  def handle_event("import_game", _, socket) do
    importable_games = Games.list_importable_games()

    {:noreply,
     socket
     |> assign(:importable_games, importable_games)
     |> assign(:show_import_modal, true)}
  end

  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, show_create_modal: false, show_import_modal: false)}
  end

  def handle_event("confirm_import", %{"source_game_id" => ""}, socket) do
    # Handle case where no game was selected
    {:noreply, put_flash(socket, :error, "Please select a game to import.")}
  end

  def handle_event("confirm_import", %{"source_game_id" => source_game_id}, socket) do
    case Games.clone_game_as_training_example(source_game_id) do
      # Destructure the game struct
      {:ok, %Game{} = imported_game} ->
        {:noreply,
         socket
         # Use imported_game
         |> put_flash(:info, "Game imported successfully as '#{imported_game.name}'.")
         |> assign(:show_import_modal, false)
         # Refresh list
         |> assign(:training_games, Games.list_training_games())
         # Navigate to new game
         # Use imported_game
         |> push_navigate(to: "/admin/training_games/#{imported_game.id}/play")}

      {:error, reason} ->
        IO.inspect(reason, label: "Import Error")
        {:noreply, put_flash(socket, :error, "Failed to import game. See server logs.")}
    end
  end

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
