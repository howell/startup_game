defmodule StartupGameWeb.GameLive.Play do
  use StartupGameWeb, :live_view

  alias StartupGame.GameService
  alias StartupGame.Games
  alias StartupGame.Games.Round
  alias StartupGameWeb.GameLive.Components.GameCreationComponent
  alias StartupGameWeb.GameLive.Components.GamePlayComponent

  @impl true
  def mount(_params, _session, socket) do
    # Initial mount - will be refined by handle_params
    socket =
      socket
      |> assign(:creation_stage, :name_input)
      |> assign(:temp_name, nil)
      |> assign(:temp_description, nil)
      |> assign(:game_id, nil)
      |> assign(:response, "")
      |> assign(:provider_preference, "StartupGame.Engine.LLMScenarioProvider")
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
  def handle_params(%{"id" => id}, _uri, socket) do
    # Handle route with ID parameter
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

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Game not found")
         |> redirect(to: ~p"/games")}
    end
  end

  @impl true
  def handle_params(%{"game_id" => game_id}, _uri, socket) when game_id != "" do
    # Handle URL with game_id query parameter
    case GameService.load_game(game_id) do
      {:ok, %{game: game, game_state: game_state}} ->
        socket =
          socket
          |> assign(:game, game)
          |> assign(:game_state, game_state)
          |> assign(:game_id, game_id)
          |> assign(:response, "")
          |> assign(:rounds, Games.list_game_rounds(game_id))
          |> assign(:ownerships, Games.list_game_ownerships(game_id))
          |> assign(:creation_stage, :playing)

        {:noreply, socket}

      {:error, _reason} ->
        # If game not found, reset to name input state
        {:noreply,
         socket
         |> put_flash(:error, "Game not found")
         |> reset_to_name_input()}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    # No game_id parameter or empty parameter
    # If we already have a game loaded (i.e., not in name/description input stage),
    # keep that state; otherwise, stay in name input stage
    if socket.assigns.creation_stage in [:name_input, :description_input] or
         socket.assigns.game_id == nil do
      {:noreply, socket}
    else
      # We have a game but no game_id in URL - keep the game
      {:noreply, socket}
    end
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
    provider = socket.assigns.provider_preference

    case GameService.create_and_start_game(
           name,
           response,
           user,
           String.to_existing_atom(provider)
         ) do
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

        # Update the URL to include the game ID without a full page navigation
        {:noreply, push_patch(socket, to: ~p"/games/play/#{game.id}", replace: true)}

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

  @impl true
  def handle_event("set_provider", %{"provider" => provider}, socket) do
    # For game creation, just store the preference in the socket
    {:noreply,
     socket
     |> assign(:provider_preference, provider)
     |> put_flash(:info, "Scenario provider set to #{provider}")}
  end

  @impl true
  def handle_event("change_provider", %{"provider" => provider}, socket) do
    game = socket.assigns.game

    case StartupGame.Games.update_provider_preference(game, provider) do
      {:ok, updated_game} ->
        {:noreply,
         socket
         |> assign(:game, updated_game)
         |> put_flash(:info, "Scenario provider updated to #{provider}")}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to update scenario provider")}
    end
  end

  # Helper to reset to name input state
  defp reset_to_name_input(socket) do
    socket
    |> assign(:creation_stage, :name_input)
    |> assign(:temp_name, nil)
    |> assign(:temp_description, nil)
    |> assign(:game_id, nil)
    |> assign(:response, "")
    |> assign(:provider_preference, "StartupGame.Engine.LLMScenarioProvider")
    |> assign(:rounds, [
      %Round{
        id: "temp_name_prompt",
        situation: "What would you like to name your company?",
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }
    ])
    |> assign(:ownerships, [])
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4 max-w-6xl">
      <%= case @creation_stage do %>
        <% stage when stage in [:name_input, :description_input] -> %>
          <GameCreationComponent.game_creation
            creation_stage={@creation_stage}
            temp_name={@temp_name}
            rounds={@rounds}
            response={@response}
            provider_preference={@provider_preference}
          />
        <% :playing -> %>
          <GamePlayComponent.game_play
            game={@game}
            game_state={@game_state}
            rounds={@rounds}
            ownerships={@ownerships}
            response={@response}
          />
      <% end %>
    </div>
    """
  end
end
