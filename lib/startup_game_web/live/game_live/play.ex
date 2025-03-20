defmodule StartupGameWeb.GameLive.Play do
  use StartupGameWeb, :live_view

  alias StartupGame.GameService
  alias StartupGame.Games
  alias StartupGame.Games.Round

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
          |> assign(:creation_stage, :playing)

        {:ok, socket, temporary_assigns: [rounds: []]}

      {:error, _reason} ->
        {:ok,
         socket
         |> put_flash(:error, "Game not found")
         |> redirect(to: ~p"/games")}
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    # New game case - setup for creation process
    socket =
      socket
      |> assign(:creation_stage, :name_input)
      |> assign(:temp_name, nil)
      |> assign(:temp_description, nil)
      |> assign(:game_id, nil)
      |> assign(:response, "")
      |> assign(:rounds, [
        %Round{
          id: "temp_name_prompt",
          situation: "What would you like to name your company?",
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }
      ])
      |> assign(:ownerships, [])

    {:ok, socket, temporary_assigns: [rounds: []]}
  end

  @impl true
  def handle_event(
        "submit_response",
        %{"response" => response},
        %{assigns: %{creation_stage: :name_input}} = socket
      )
      when response != "" do
    # Store the company name and transition to description input
    socket =
      socket
      |> assign(:temp_name, response)
      |> assign(:creation_stage, :description_input)
      |> assign(:response, "")
      |> assign(:rounds, [
        %Round{
          id: "temp_name_prompt",
          situation: "What would you like to name your company?",
          response: response,
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        },
        %Round{
          id: "temp_description_prompt",
          situation: "Please provide a brief description of what #{response} does:",
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }
      ])

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "submit_response",
        %{"response" => response},
        %{assigns: %{creation_stage: :description_input}} = socket
      )
      when response != "" do
    # Create the game with the collected name and description
    user = socket.assigns.current_user
    name = socket.assigns.temp_name

    case GameService.create_and_start_game(name, response, user) do
      {:ok, %{game: game, game_state: game_state}} ->
        socket =
          socket
          |> assign(:game, game)
          |> assign(:game_state, game_state)
          |> assign(:game_id, game.id)
          |> assign(:creation_stage, :playing)
          |> assign(:response, "")
          |> assign(:rounds, Games.list_game_rounds(game.id))
          |> assign(:ownerships, Games.list_game_ownerships(game.id))
          |> put_flash(:info, "Started new venture: #{game.name}")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create game: Invalid input")}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create game: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event(
        "submit_response",
        %{"response" => response},
        %{assigns: %{creation_stage: :playing}} = socket
      )
      when response != "" do
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
