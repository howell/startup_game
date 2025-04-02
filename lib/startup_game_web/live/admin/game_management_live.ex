defmodule StartupGameWeb.Admin.GameManagementLive do
  use StartupGameWeb, :live_view

  alias StartupGame.Games

  @impl true
  def mount(_params, _session, socket) do
    # Preload user data for display
    games = Games.list_games() |> StartupGame.Repo.preload(:user)

    socket =
      assign(socket,
        page_title: "Manage Games",
        games: games,
        # For delete confirmation modal
        game_to_delete: nil
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto px-20 mt-20">
      <.header class="mb-6">
        Manage Games
        <:subtitle>View and delete games.</:subtitle>
      </.header>

      <.table id="games" rows={@games}>
        <:col :let={game} label="Name">{game.name}</:col>
        <:col :let={game} label="Owner">{game.user.username || game.user.email}</:col>
        <:col :let={game} label="Status">{game.status}</:col>
        <:col :let={game} label="Created">{DateTime.to_string(game.inserted_at)}</:col>
        <:action :let={game}>
          <div class="sr-only">
            <.link navigate={~p"/games/view/#{game.id}"}>Show</.link>
          </div>
          <.link
            phx-click={JS.push("open_delete_modal", value: %{game_id: game.id})}
            class="text-red-600 hover:text-red-900"
          >
            Delete
          </.link>
        </:action>
      </.table>

      <%!-- Delete Confirmation Modal --%>
      <.modal
        :if={@game_to_delete}
        id="delete-game-modal"
        show
        on_cancel={JS.push("close_delete_modal")}
      >
        <div class="p-4">
          <h2 class="text-lg font-semibold mb-4">Confirm Deletion</h2>
          <p class="mb-6">
            Are you sure you want to delete game "<span class="font-medium"><%= @game_to_delete && @game_to_delete.name %></span>"
            owned by <span class="font-medium"><%= @game_to_delete && (@game_to_delete.user.username || @game_to_delete.user.email) %></span>?
            This action cannot be undone and will delete all associated rounds and ownership data.
          </p>
          <.button
            phx-click="delete_game"
            phx-value-game_id={@game_to_delete && @game_to_delete.id}
            class="bg-red-600 hover:bg-red-700"
          >
            Delete Game
          </.button>
          <.button phx-click="close_delete_modal" class="ml-4 bg-gray-400 hover:bg-gray-500">
            Cancel
          </.button>
        </div>
      </.modal>
    </div>
    """
  end

  # Event Handlers

  @impl true
  def handle_event("open_delete_modal", %{"game_id" => game_id}, socket) do
    game_to_delete = Enum.find(socket.assigns.games, &(&1.id == game_id))
    {:noreply, assign(socket, game_to_delete: game_to_delete)}
  end

  @impl true
  def handle_event("close_delete_modal", _, socket) do
    {:noreply, assign(socket, game_to_delete: nil)}
  end

  @impl true
  def handle_event("delete_game", %{"game_id" => game_id}, socket) do
    game_to_delete = socket.assigns.game_to_delete

    if game_to_delete && game_to_delete.id == game_id do
      case Games.delete_game(game_to_delete) do
        {:ok, _deleted_game} ->
          games = Enum.reject(socket.assigns.games, &(&1.id == game_id))

          socket =
            socket
            |> assign(games: games, game_to_delete: nil)
            |> put_flash(:info, "Game \"#{game_to_delete.name}\" deleted successfully.")

          {:noreply, socket}

        {:error, changeset} ->
          socket =
            put_flash(socket, :error, "Failed to delete game: #{inspect(changeset.errors)}")
            # Close modal on error
            |> assign(game_to_delete: nil)

          {:noreply, socket}
      end
    else
      # Game ID mismatch or game_to_delete is nil
      socket =
        put_flash(socket, :error, "Could not find game to delete.")
        |> assign(game_to_delete: nil)

      {:noreply, socket}
    end
  end
end
