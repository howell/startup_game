defmodule StartupGameWeb.Admin.TrainingGameLive.FormComponent do
  use StartupGameWeb, :live_component

  alias StartupGame.Games
  alias StartupGame.Games.Game
  # To get default prompts
  alias StartupGame.Engine.LLMScenarioProvider

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="training-game-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input field={@form[:description]} type="textarea" label="Description" required />
        <.input
          field={@form[:scenario_system_prompt]}
          type="textarea"
          label="Scenario System Prompt"
          rows="10"
        />
        <.input
          field={@form[:outcome_system_prompt]}
          type="textarea"
          label="Outcome System Prompt"
          rows="10"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Create Training Game</.button>
          <.button type="button" class="ml-2" phx-click="cancel" phx-target={@myself}>
            Cancel
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{game: game} = assigns, socket) do
    # This case handles editing an existing game (not needed for create, but good structure)
    changeset = Games.change_game(game)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  def update(assigns, socket) do
    # This case handles creating a new game
    # Pre-fill prompts with defaults
    default_prompts = %{
      scenario_system_prompt: LLMScenarioProvider.scenario_system_prompt(),
      outcome_system_prompt: LLMScenarioProvider.outcome_system_prompt()
    }

    changeset = Games.change_game(%Game{}, default_prompts)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"game" => game_params}, socket) do
    changeset =
      %Game{}
      |> Games.change_game(game_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"game" => game_params}, socket) do
    save_game(socket, socket.assigns.live_action, game_params)
  end

  def handle_event("cancel", _, socket) do
    # Send message to parent to close the modal/component
    send(socket.assigns.parent_pid || self(), {:close_game_form})
    {:noreply, socket}
  end

  defp save_game(socket, :new, game_params) do
    current_user = socket.assigns.current_user

    # Add required fields not in the form
    attrs =
      Map.merge(game_params, %{
        "user_id" => current_user.id,
        "is_training_example" => true,
        # Set initial financial state (can be adjusted later if needed)
        "cash_on_hand" => Decimal.new("10000.00"),
        "burn_rate" => Decimal.new("1000.00"),
        "status" => :in_progress,
        "is_public" => false,
        "is_leaderboard_eligible" => false
      })

    case Games.create_game(attrs) do
      {:ok, game} ->
        # Notify parent about successful creation and potentially redirect
        send(socket.assigns.parent_pid || self(), {:saved_game, game})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # save_game for :edit action (if needed later)
  # defp save_game(socket, :edit, game_params) do ... end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
