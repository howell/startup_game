defmodule StartupGameWeb.Admin.TrainingGameLive.EditOutcomeComponent do
  use StartupGameWeb, :live_component

  alias StartupGame.Games

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id={"edit-outcome-form-#{@round.id}"}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <h3 class="text-md font-semibold mb-4">Edit Round Outcome (ID: {@round.id})</h3>

        <.input field={@form[:outcome]} type="textarea" label="Outcome Narrative" rows="10" />
        <.input field={@form[:cash_change]} type="number" label="Cash Change" step="any" />
        <.input field={@form[:burn_rate_change]} type="number" label="Burn Rate Change" step="any" />

        <%!-- TODO: Add better UI for ownership changes --%>
        <%!-- For now, maybe just display existing ones read-only? --%>
        <%!-- Or allow editing raw JSON? Needs more thought. --%>
        <p class="text-sm text-gray-600 mt-4">Ownership changes editing not yet implemented.</p>

        <%!-- TODO: Add fields for exit_type and exit_value if applicable --%>
        <p class="text-sm text-gray-600 mt-2">Exit editing not yet implemented.</p>

        <:actions>
          <.button phx-disable-with="Saving...">Save Changes</.button>
          <.button type="button" class="ml-2" phx-click="cancel" phx-target={@myself}>
            Cancel
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{round: round} = assigns, socket) do
    changeset = Games.change_round(round)

    {:ok,
     socket
     |> assign(assigns)
     # Store ID for save handler
     |> assign(:round_id, round.id)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"round" => round_params}, socket) do
    # Fetch the original round to create a valid changeset base
    round = Games.get_round!(socket.assigns.round_id)

    changeset =
      Games.change_round(round, round_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"round" => round_params}, socket) do
    save_outcome(socket, round_params)
  end

  def handle_event("cancel", _, socket) do
    send(socket.assigns.parent_pid || self(), {:close_edit_outcome_form})
    {:noreply, socket}
  end

  defp save_outcome(socket, round_params) do
    round = Games.get_round!(socket.assigns.round_id)

    # TODO: Handle ownership changes and exit data properly when implemented
    allowed_attrs = Map.take(round_params, ["outcome", "cash_change", "burn_rate_change"])

    case Games.update_round(round, allowed_attrs) do
      {:ok, updated_round} ->
        send(socket.assigns.parent_pid || self(), {:saved_outcome, updated_round})
        # No flash here, parent will handle
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
