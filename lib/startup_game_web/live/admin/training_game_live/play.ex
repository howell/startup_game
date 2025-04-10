defmodule StartupGameWeb.Admin.TrainingGameLive.Play do
  use StartupGameWeb, :live_view

  alias StartupGame.Games
  alias StartupGameWeb.Admin.TrainingGameLive.EditOutcomeComponent # Add alias

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    game = Games.get_game_with_associations(game_id)

    # Ensure this is actually a training game accessed by an admin
    # (Authorization handled by router plug, but double-check type here)
    if game && game.is_training_example do
      socket =
        socket
        |> assign(:game, game)
        |> assign(:page_title, "Play/Edit Training Game: #{game.name}")
        # Ensure sorted
        |> assign(:rounds, Enum.sort_by(game.rounds, & &1.inserted_at))
        |> assign(:show_edit_modal, false)
        |> assign(:editing_round_id, nil)

      {:ok, socket}
    else
      # Redirect if somehow a non-training game ID is accessed via this route
      socket =
        socket
        |> put_flash(:error, "Game not found or not a training game")
        |> redirect(to: ~p"/admin/training_games")

      {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Training Game: {@game.name}
      <:subtitle>ID: {@game.id}</:subtitle>
      <%!-- TODO: Add actions like Edit Prompts --%>
    </.header>

    <div class="mt-6 border rounded-lg p-4">
      <h3 class="text-md font-semibold mb-2">Game Description</h3>
      <p class="text-sm text-gray-700">{@game.description}</p>
    </div>

    <div class="mt-6">
      <h3 class="text-lg font-semibold mb-4">Game History</h3>
      <div class="space-y-6">
        <div :for={round <- @rounds} class="border rounded-lg p-4 shadow-sm">
          <p class="text-xs text-gray-500 mb-2">Round ##{round.id} - {round.inserted_at}</p>

          <div :if={round.situation} class="mb-4 p-3 bg-blue-50 rounded">
            <p class="font-semibold text-blue-800">Situation:</p>
            <p class="text-sm text-blue-700 whitespace-pre-wrap">{round.situation}</p>
          </div>

          <div :if={round.player_input} class="mb-4 p-3 bg-green-50 rounded">
            <p class="font-semibold text-green-800">Player Input:</p>
            <p class="text-sm text-green-700 whitespace-pre-wrap">{round.player_input}</p>
          </div>

          <div :if={round.outcome} class="mb-4 p-3 bg-purple-50 rounded">
            <p class="font-semibold text-purple-800">Outcome:</p>
            <p class="text-sm text-purple-700 whitespace-pre-wrap">{round.outcome}</p>
            <%!-- TODO: Add Edit/Regenerate buttons here --%>
            <div class="mt-2 flex justify-end gap-2">
              <.button type="button" class="text-xs" phx-click="edit_outcome" phx-value-round_id={round.id}>Edit</.button>
              <.button type="button" class="text-xs" disabled>Regenerate</.button> <% # TODO: Implement Regenerate %>
            </div>
          </div>

          <div class="text-xs text-gray-600 border-t pt-2 mt-2">
            <span>Cash Change: {round.cash_change || 0}</span>
            | <span>Burn Rate Change: {round.burn_rate_change || 0}</span>
            <%!-- TODO: Display ownership changes nicely --%>
          </div>
        </div>

        <div :if={@rounds == []}>
          <p>No rounds have been played in this game yet.</p>
        </div>
      </div>
    </div>

    <.modal :if={@show_edit_modal} id="edit-outcome-modal" show on_cancel={JS.push("close_edit_modal")}>
      <.live_component
        :if={@editing_round_id}
        module={EditOutcomeComponent}
        id={"edit-outcome-#{ @editing_round_id}"}
        round={find_round(@rounds, @editing_round_id)}
        parent_pid={self()}
      />
    </.modal>
    """
  end

  @impl true
  def handle_event("edit_outcome", %{"round_id" => round_id}, socket) do
    {:noreply,
     socket
     |> assign(:editing_round_id, round_id)
     |> assign(:show_edit_modal, true)}
  end

  def handle_event("close_edit_modal", _, socket) do
    {:noreply, assign(socket, show_edit_modal: false, editing_round_id: nil)}
  end

  # TODO: Add handler for regenerate

  @impl true
  def handle_info({:close_edit_outcome_form}, socket) do
    {:noreply, assign(socket, show_edit_modal: false, editing_round_id: nil)}
  end

  def handle_info({:saved_outcome, updated_round}, socket) do
    # Replace the round in the assigns list and close modal
    updated_rounds =
      Enum.map(socket.assigns.rounds, fn round ->
        if round.id == updated_round.id, do: updated_round, else: round
      end)

    {:noreply,
     socket
     |> assign(:rounds, updated_rounds)
     |> assign(:show_edit_modal, false)
     |> assign(:editing_round_id, nil)
     |> put_flash(:info, "Round outcome updated successfully.")}
  end

  # Helper to find the round struct from the list in assigns
  defp find_round(rounds, round_id) do
    Enum.find(rounds, &(&1.id == round_id))
  end
end
