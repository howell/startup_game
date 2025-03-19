defmodule StartupGameWeb.GameLive.Play do
  use StartupGameWeb, :live_view

  alias StartupGame.GameService
  alias StartupGame.Games

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case GameService.load_game(id) do
      {:ok, %{game: game, game_state: game_state}} ->
        socket =
          socket
          |> assign(:game, game)
          |> assign(:game_state, game_state)
          |> assign(:game_id, id)
          |> assign(:response, "")
          |> assign(:rounds, Games.list_game_rounds(id))
          |> assign(:ownerships, Games.list_game_ownerships(id))

        {:ok, socket, temporary_assigns: [rounds: []]}

      {:error, _reason} ->
        {:ok,
         socket
         |> put_flash(:error, "Game not found")
         |> redirect(to: ~p"/games")}
    end
  end

  @impl true
  def handle_event("submit_response", %{"response" => response}, socket) when response != "" do
    game_id = socket.assigns.game_id

    case GameService.process_response(game_id, response) do
      {:ok, %{game: updated_game, game_state: updated_state}} ->
        socket =
          socket
          |> assign(:game, updated_game)
          |> assign(:game_state, updated_state)
          |> assign(:response, "")
          # Reload rounds and ownerships
          |> assign(:rounds, Games.list_game_rounds(game_id))
          |> assign(:ownerships, Games.list_game_ownerships(game_id))

        {:noreply, socket}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error processing response: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("submit_response", _params, socket) do
    # Empty response, do nothing
    {:noreply, socket}
  end

  # Helper functions for formatting display values
  defp format_money(value) do
    value
    |> Decimal.to_float()
    |> :erlang.float_to_binary(decimals: 2)
  end

  defp format_percentage(value) do
    value
    |> Decimal.to_float()
    |> :erlang.float_to_binary(decimals: 1)
  end

  defp format_runway(value) do
    value
    |> Decimal.to_float()
    |> :erlang.float_to_binary(decimals: 1)
  end

  defp game_end_status(%{status: :completed, exit_type: :acquisition}), do: "Acquired!"
  defp game_end_status(%{status: :completed, exit_type: :ipo}), do: "IPO Successful!"
  defp game_end_status(%{status: :failed}), do: "Failed"

  defp game_end_message(%{status: :completed, exit_type: :acquisition, exit_value: value}) do
    "Congratulations! Your company was acquired for $#{format_money(value)}."
  end

  defp game_end_message(%{status: :completed, exit_type: :ipo, exit_value: value}) do
    "Congratulations! Your company went public with a valuation of $#{format_money(value)}."
  end

  defp game_end_message(%{status: :failed, exit_type: :shutdown}) do
    "Unfortunately, your startup ran out of money and had to shut down."
  end

  defp game_end_message(_game) do
    "Your startup journey has ended."
  end
end
