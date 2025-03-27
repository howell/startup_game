defmodule StartupGameWeb.GameLive.Index do
  use StartupGameWeb, :live_view

  alias StartupGame.Games

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    games = Games.list_user_games(user.id) |> Enum.sort_by(& &1.inserted_at, :desc)

    {:ok, assign(socket, :games, games)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "My Games")
  end

  # Helper functions for formatting display values
  defp format_money(value) do
    value
    |> Decimal.to_float()
    |> :erlang.float_to_binary(decimals: 2)
  end

  defp format_status(:in_progress), do: "In Progress"
  defp format_status(:completed), do: "Completed"
  defp format_status(:failed), do: "Failed"

  defp status_color(:in_progress), do: "text-blue-600"
  defp status_color(:completed), do: "text-green-600"
  defp status_color(:failed), do: "text-red-600"

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y")
  end

  defp game_action_text(%{status: :in_progress}), do: "Continue Game"
  defp game_action_text(%{status: :completed}), do: "View Results"
  defp game_action_text(%{status: :failed}), do: "View Results"

  @impl true
  def handle_event("toggle_visibility", %{"id" => id, "field" => field}, socket) do
    # Find the game in the list
    game = Enum.find(socket.assigns.games, fn g -> g.id == id end)

    if game do
      field_atom = String.to_existing_atom(field)
      current_value = Map.get(game, field_atom)

      # Toggle the value
      {:ok, _updated_game} = Games.update_game(game, %{field_atom => !current_value})

      # Refresh the games list
      games = Games.list_user_games(socket.assigns.current_user.id)
      {:noreply, assign(socket, games: games)}
    else
      {:noreply, socket}
    end
  end
end
