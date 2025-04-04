defmodule StartupGameWeb.Admin.DashboardLive do
  use StartupGameWeb, :live_view

  alias StartupGame.Accounts
  alias StartupGame.Games

  @impl true
  def mount(_params, _session, socket) do
    total_users = Accounts.count_users()
    recent_users = Accounts.list_recent_users()
    total_games = Games.count_games()
    recent_games = Games.list_recent_games()

    socket =
      assign(socket,
        page_title: "Admin Dashboard",
        total_users: total_users,
        recent_users: recent_users,
        total_games: total_games,
        recent_games: recent_games
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto px-20 mt-20">
      <.header class="mb-6">
        Admin Dashboard
        <:subtitle>Overview and management tools.</:subtitle>
      </.header>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <.card title="Total Users" id="total-users-card">
          <span class="text-2xl font-bold">{@total_users}</span>
        </.card>
        <.card title="Total Games" id="total-games-card">
          <span class="text-2xl font-bold">{@total_games}</span>
        </.card>
        <%!-- Add more stat cards later --%>
      </div>

      <div class="space-y-4">
        <.link
          navigate={~p"/admin/users"}
          class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          Manage Users
        </.link>
        <.link
          navigate={~p"/admin/games"}
          class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          Manage Games
        </.link>
      </div>

      <h2 class="text-xl font-semibold mt-8 mb-4">Recent Users</h2>
      <.table id="recent-users" rows={@recent_users}>
        <:col :let={user} label="Email">{user.email}</:col>
        <:col :let={user} label="Username">{user.username || "--"}</:col>
        <:col :let={user} label="Role">{user.role}</:col>
        <:col :let={user} label="Joined">{DateTime.to_string(user.inserted_at)}</:col>
      </.table>

      <h2 class="text-xl font-semibold mt-8 mb-4">Recent Games</h2>
      <.table id="recent-games" rows={@recent_games}>
        <:col :let={game} label="Name">{game.name}</:col>
        <:col :let={game} label="Status">{game.status}</:col>
        <:col :let={game} label="Created">{DateTime.to_string(game.inserted_at)}</:col>
        <%!-- Add more game columns as needed --%>
      </.table>
    </div>
    """
  end

  # Helper component (can be moved to core_components later if reused)
  defp card(assigns) do
    ~H"""
    <div class="bg-white overflow-hidden shadow rounded-lg" id={@id}>
      <div class="p-5">
        <dt class="text-sm font-medium text-gray-500 truncate">
          {@title}
        </dt>
        <dd class="mt-1 text-3xl font-semibold text-gray-900">
          {render_slot(@inner_block)}
        </dd>
      </div>
    </div>
    """
  end
end
