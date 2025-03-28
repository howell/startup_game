defmodule StartupGameWeb.GameLive.View do
  @moduledoc """
  LiveView for viewing public games.
  Provides a read-only view of public games for anyone to see.
  """

  use StartupGameWeb, :live_view

  alias StartupGame.Games
  alias StartupGame.GameService
  alias StartupGameWeb.GameLive.Components.GamePlayComponent
  alias StartupGameWeb.GameLive.Helpers.SocketAssignments

  @type t :: Phoenix.LiveView.Socket.t()

  @impl true
  @spec mount(map(), map(), t()) :: {:ok, t()}
  def mount(_params, _session, socket) do
    socket = assign(socket, :is_mobile_state_visible, false)

    {:ok, socket}
  end

  @impl true
  @spec handle_params(map(), String.t(), t()) :: {:noreply, t()}
  def handle_params(%{"id" => id}, _uri, socket) do
    case validate_and_load_game(id) do
      {:ok, %{game: game, game_state: game_state}} ->
        socket =
          socket
          |> SocketAssignments.assign_game_data(
            game,
            game_state,
            Games.list_game_rounds(id),
            Games.list_game_ownerships(id)
          )
          |> assign(:is_view_only, true)

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Game not found or not public")
         |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "No game specified")
     |> redirect(to: ~p"/")}
  end

  @impl true
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="container">
      <GamePlayComponent.game_play
        game={@game}
        game_state={@game_state}
        rounds={@rounds}
        ownerships={@ownerships}
        is_view_only={true}
        is_mobile_state_visible={@is_mobile_state_visible}
      />
    </div>
    """
  end

  @impl true
  @spec handle_event(String.t(), map(), t()) :: {:noreply, t()}
  def handle_event("toggle_mobile_state", _, socket) do
    {:noreply, assign(socket, is_mobile_state_visible: !socket.assigns.is_mobile_state_visible)}
  end

  # Private functions

  @spec validate_and_load_game(String.t()) ::
          {:ok, %{game: Games.Game.t(), game_state: map()}}
          | {:error, String.t()}
  defp validate_and_load_game(id) do
    with {:ok, %{game: game, game_state: game_state}} <- GameService.load_game(id),
         true <- game.is_public do
      {:ok, %{game: game, game_state: game_state}}
    else
      false -> {:error, "Game is not public"}
      error -> error
    end
  end
end
