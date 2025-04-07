defmodule StartupGameWeb.GameLive.Play do
  @moduledoc """
  LiveView for the game play interface.
  Coordinates game creation, gameplay, and streaming functionality.
  """

  use StartupGameWeb, :live_view

  alias StartupGame.Games.Round
  alias StartupGameWeb.GameLive.Components.{GameCreationComponent, GamePlayComponent}
  alias StartupGameWeb.GameLive.Handlers.{CreationHandler, PlayHandler, StreamHandler}
  alias StartupGameWeb.GameLive.Helpers.SocketAssignments
  alias StartupGame.GameService

  @type t :: Phoenix.LiveView.Socket.t()

  @impl true
  @spec mount(map(), map(), t()) :: {:ok, t(), keyword()}
  def mount(_params, _session, socket) do
    initial_round = %Round{
      id: "temp_name_prompt",
      situation: "What would you like to name your company?",
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

    socket = SocketAssignments.initialize_socket(socket, initial_round)
    socket = assign(socket, :provider_preference, default_provider_preference())
    socket = assign(socket, :is_mobile_state_visible, false)
    # Initialize player_mode (will be properly set in handle_params/CreationHandler)
    socket = assign(socket, :player_mode, :responding)

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
  @spec handle_params(map(), String.t(), t()) :: {:noreply, t()}
  def handle_params(%{"id" => id}, _uri, socket) do
    if connected?(socket) do
      CreationHandler.handle_existing_game(socket, id)
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    CreationHandler.handle_no_game_id(socket)
  end

  @impl true
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="container ">
      <%= case @creation_stage do %>
        <% stage when stage in [:name_input, :description_input] -> %>
          <GameCreationComponent.game_creation
            creation_stage={@creation_stage}
            temp_name={@temp_name}
            rounds={@rounds}
            response={@response}
            provider_preference={@provider_preference}
            streaming={@streaming}
            streaming_type={@streaming_type}
            partial_content={@partial_content}
            is_mobile_state_visible={@is_mobile_state_visible}
            initial_player_mode={@initial_player_mode}
          />
        <% :playing -> %>
          <GamePlayComponent.game_play
            game={@game}
            rounds={@rounds}
            ownerships={@ownerships}
            response={@response}
            streaming={@streaming}
            streaming_type={@streaming_type}
            partial_content={@partial_content}
            is_mobile_state_visible={@is_mobile_state_visible}
          />
      <% end %>
    </div>
    """
  end

  # Event handlers delegate to the appropriate handler modules
  @impl true
  @spec handle_event(String.t(), map(), t()) :: {:noreply, t()}
  def handle_event("submit_response", %{"response" => response}, socket) when response != "" do
    case socket.assigns.creation_stage do
      :name_input ->
        CreationHandler.handle_name_input(socket, response)

      :description_input ->
        CreationHandler.handle_description_input(socket, response)

      :playing ->
        PlayHandler.handle_play_response(socket, response)
    end
  end

  @impl true
  def handle_event("submit_response", _params, socket) do
    # Empty response, do nothing
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_mobile_state", _, socket) do
    {:noreply, assign(socket, is_mobile_state_visible: !socket.assigns.is_mobile_state_visible)}
  end

  @impl true
  def handle_event("set_provider", %{"provider" => provider}, socket) do
    CreationHandler.handle_provider_change(socket, provider)
  end

  @impl true
  def handle_event("change_provider", %{"provider" => provider}, socket) do
    PlayHandler.handle_provider_change(socket, provider)
  end

  @impl true
  def handle_event("set_initial_mode", %{"mode" => mode}, socket) do
    CreationHandler.handle_initial_mode_change(socket, mode)
  end

  @impl true
  def handle_event("toggle_visibility", %{"field" => field}, socket) do
    # Handle visibility toggle for the current game
    field_atom = String.to_existing_atom(field)
    current_value = Map.get(socket.assigns.game, field_atom)

    # Toggle the value
    {:ok, updated_game} =
      StartupGame.Games.update_game(
        socket.assigns.game,
        %{field_atom => !current_value}
      )

    # Update the socket assigns with the updated game
    {:noreply, assign(socket, game: updated_game)}
  end

  @impl true
  def handle_event("take_initiative", _, socket) do
    # Update mode locally and in DB
    socket = assign(socket, player_mode: :acting)
    # Clear current scenario visually immediately using full module name
    GameService.update_player_mode(socket.assigns.game.id, "acting")
    {:noreply, socket}
  end

  @impl true
  def handle_event("await_situation", _, socket) do
    # Update mode locally and in DB, request next scenario
    socket = assign(socket, player_mode: :responding, streaming: true, streaming_type: :scenario)
    GameService.update_player_mode(socket.assigns.game.id, "responding")
    GameService.request_next_scenario_async(socket.assigns.game.id)
    {:noreply, socket}
  end

  # Info handlers delegate to the StreamHandler
  @impl true
  @spec handle_info(map(), t()) :: {:noreply, t()}
  def handle_info(%{event: "llm_delta", payload: payload}, socket) do
    StreamHandler.handle_delta(socket, payload)
  end

  @impl true
  def handle_info(%{event: "llm_complete", payload: payload}, socket) do
    StreamHandler.handle_complete(socket, payload)
  end

  @impl true
  def handle_info(%{event: "llm_error", payload: payload}, socket) do
    StreamHandler.handle_error(socket, payload)
  end

  @impl true
  def handle_info({_ref, :ok}, socket) do
    StreamHandler.handle_task_complete(socket, :ok)
  end

  @impl true
  def handle_info({_ref, {:ok, result}}, socket) do
    StreamHandler.handle_task_complete(socket, {:ok, result})
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, reason}, socket) do
    StreamHandler.handle_task_down(socket, reason)
  end
end
