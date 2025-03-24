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
      |> assign(:provider_preference, default_provider_preference())
      |> assign(:rounds, [
        %Round{
          id: "temp_name_prompt",
          situation: "What would you like to name your company?",
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }
      ])
      |> assign(:ownerships, [])
      |> assign(:streaming, false)
      |> assign(:stream_id, nil)
      |> assign(:partial_content, "")

    {:ok, socket, temporary_assigns: [rounds: []]}
  end

  @spec default_provider_preference() ::
          StartupGame.Engine.Demo.StaticScenarioProvider | StartupGame.Engine.LLMScenarioProvider
  def default_provider_preference() do
    case Application.fetch_env(:startup_game, :env) do
      {:ok, :prod} -> StartupGame.Engine.LLMScenarioProvider
      _ -> StartupGame.Engine.Demo.StaticScenarioProvider
    end
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
           provider
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

    # Create a temporary round entry for the response
    updated_round = Games.list_game_rounds(game_id) |> List.last() |> Map.put(:response, response)

    # Start the async response processing
    case GameService.process_response_async(game_id, response) do
      {:ok, stream_id} ->
        # Subscribe to the streaming topic
        StartupGameWeb.Endpoint.subscribe("llm_stream:#{game_id}")

        socket =
          socket
          |> assign(:streaming, true)
          |> assign(:stream_id, stream_id)
          |> assign(:partial_content, "")
          |> assign(:response, "")
          |> assign(:rounds, [updated_round])

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
    provider = String.to_existing_atom(provider)

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

  @impl true
  def handle_info(
        %{event: "llm_delta", payload: {:llm_delta, stream_id, _delta, full_content}},
        socket
      ) do
    if socket.assigns.stream_id == stream_id and socket.assigns.streaming do
      # Update the partial content
      socket =
        socket
        |> assign(:partial_content, full_content)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        %{event: "llm_complete", payload: {:llm_complete, stream_id, {:ok, result}}},
        socket
      ) do
    if socket.assigns.stream_id == stream_id and socket.assigns.streaming do
      game_id = socket.assigns.game_id

      # Process the completed response based on what we're streaming
      # (Either a scenario or an outcome)
      case result do
        %{situation: _} = scenario ->
          # We received a scenario
          {:ok, %{game: updated_game, game_state: updated_state}} =
            GameService.finalize_streamed_scenario(game_id, scenario)

          socket =
            socket
            |> assign(:game, updated_game)
            |> assign(:game_state, updated_state)
            |> assign(:streaming, false)
            |> assign(:stream_id, nil)
            |> assign(:partial_content, "")
            |> assign(:rounds, Games.list_game_rounds(game_id))

          {:noreply, socket}

        %{text: _} = outcome ->
          # We received an outcome
          {:ok, %{game: updated_game, game_state: updated_state}} =
            GameService.finalize_streamed_outcome(game_id, outcome)

          socket =
            socket
            |> assign(:game, updated_game)
            |> assign(:game_state, updated_state)
            |> assign(:streaming, false)
            |> assign(:stream_id, nil)
            |> assign(:partial_content, "")
            |> assign(:rounds, Games.list_game_rounds(game_id))
            |> assign(:ownerships, Games.list_game_ownerships(game_id))

          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%{event: "llm_error", payload: {:llm_error, stream_id, error}}, socket) do
    if socket.assigns.stream_id == stream_id and socket.assigns.streaming do
      socket =
        socket
        |> assign(:streaming, false)
        |> assign(:stream_id, nil)
        |> assign(:partial_content, "")
        |> put_flash(:error, "Error: #{error}")

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({_ref, :ok}, socket) do
    # Ignore Task completion messages
    {:noreply, socket}
  end

  @impl true
  def handle_info({_ref, {:ok, _}}, socket) do
    # Also ignore Task completion messages with {:ok, _} results
    {:noreply, socket}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    # Ignore Task process DOWN messages
    {:noreply, socket}
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
            streaming={@streaming}
            partial_content={@partial_content}
          />
      <% end %>
    </div>
    """
  end
end
