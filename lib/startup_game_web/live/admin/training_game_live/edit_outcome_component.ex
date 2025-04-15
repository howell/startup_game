defmodule StartupGameWeb.Admin.TrainingGameLive.EditOutcomeComponent do
  use StartupGameWeb, :live_component

  alias StartupGame.Games
  alias StartupGame.TrainingGames

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

        <%!-- Display Ownership Changes Read-Only --%>
        <div class="mt-4 pt-4 border-t">
          <h4 class="text-sm font-semibold mb-2">Ownership Changes in this Round:</h4>
          <div :if={Enum.empty?(@round.ownership_changes)} class="text-sm text-gray-500">
            None
          </div>
          <ul :if={not Enum.empty?(@round.ownership_changes)} class="list-disc pl-5 space-y-1 text-sm">
            <li :for={change <- @round.ownership_changes}>
              <span class="font-medium">{change.entity_name}:</span>
              {change.previous_percentage}% &rarr; {change.new_percentage}%
              ({change.change_type})
            </li>
          </ul>
          <p class="text-xs text-gray-500 mt-1">
            (Ownership changes are recorded automatically and cannot be edited here.)
          </p>
        </div>

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
    # Ensure ownership_changes are loaded (should be by Play LV now)
    round = Map.put(round, :ownership_changes, ensure_loaded(round.ownership_changes))
    changeset = Games.change_round(round)

    {:ok,
     socket
     |> assign(assigns)
     # Assign potentially reloaded round
     |> assign(:round, round)
     # Store ID for save handler
     |> assign(:round_id, round.id)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"round" => round_params}, socket) do
    round = Games.get_round!(socket.assigns.round_id)

    # Only validate fields present in the form
    changeset =
      Games.change_round(round, round_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"round" => round_params}, socket) do
    case TrainingGames.update_round_outcome(socket.assigns.round_id, round_params) do
      {:ok, updated_round} ->
        send(socket.assigns.parent_pid || self(), {:saved_outcome, updated_round})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("cancel", _, socket) do
    send(socket.assigns.parent_pid || self(), {:close_edit_outcome_form})
    {:noreply, socket}
  end

  # --- Form Helpers ---

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  # Helper to ensure association is loaded or return empty list
  defp ensure_loaded(%Ecto.Association.NotLoaded{}), do: []
  defp ensure_loaded(loaded_data), do: loaded_data
end
