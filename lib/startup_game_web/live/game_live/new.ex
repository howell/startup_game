defmodule StartupGameWeb.GameLive.New do
  use StartupGameWeb, :live_view

  alias StartupGame.GameService
  alias StartupGame.Games.Game

  @impl true
  def mount(_params, _session, socket) do
    changeset = StartupGame.Games.change_game(%Game{})

    {:ok,
     socket
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"game" => game_params}, socket) do
    user = socket.assigns.current_user

    case GameService.create_and_start_game(
           game_params["name"],
           game_params["description"],
           user
         ) do
      {:ok, %{game: game}} ->
        {:noreply,
         socket
         |> put_flash(:info, "Started new venture: #{game.name}")
         |> redirect(to: ~p"/games/play/#{game.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create game")
         |> assign(:changeset, StartupGame.Games.change_game(%Game{}))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto bg-white p-8 rounded-lg shadow-md mt-10">
      <h1 class="text-2xl font-bold mb-6">Start a New Venture</h1>

      <.form :let={f} for={@changeset} phx-submit="save" class="space-y-6">
        <div>
          <.input field={f[:name]} label="Startup Name" required />
          <div class="text-xs text-gray-500 mt-1">What's your company called?</div>
        </div>

        <div>
          <.input field={f[:description]} type="textarea" label="What does your company do?" required />
          <div class="text-xs text-gray-500 mt-1">
            Describe your startup idea in a few sentences (e.g., "Uber for dog walking")
          </div>
        </div>

        <div class="pt-4">
          <.button class="w-full bg-blue-600 hover:bg-blue-700">Launch Startup</.button>
        </div>
      </.form>

      <div class="mt-6 text-center">
        <.link navigate={~p"/games"} class="text-sm text-gray-600 hover:text-gray-900">
          &larr; Back to My Games
        </.link>
      </div>
    </div>
    """
  end
end
