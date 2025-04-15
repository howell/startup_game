defmodule StartupGame.TrainingGames do
  @moduledoc """
  Context module for managing training game data and operations,
  like regenerating outcomes.
  """

  alias StartupGame.Repo
  alias StartupGame.Games
  alias StartupGame.Games.{Game, Round}
  alias StartupGame.GameService
  alias StartupGame.Engine.Scenario

  require Logger

  @doc """
  Updates a round's outcome details (outcome text, cash change, burn rate change)
  and returns the updated round with ownership changes preloaded.

  ## Parameters
    - round_id: The UUID of the round to update
    - attrs: Map of attributes to update, with string keys: "outcome", "cash_change", "burn_rate_change"

  ## Returns
    - {:ok, %Round{}} with preloaded ownership_changes on success
    - {:error, %Ecto.Changeset{}} on validation failure
  """
  @spec update_round_outcome(Ecto.UUID.t(), map()) ::
          {:ok, Round.t()} | {:error, Ecto.Changeset.t()}
  def update_round_outcome(round_id, attrs) when is_map(attrs) do
    round = Games.get_round!(round_id)

    # Only take allowed fields for update_round
    allowed_attrs = Map.take(attrs, ["outcome", "cash_change", "burn_rate_change"])

    case Games.update_round(round, allowed_attrs) do
      {:ok, updated_round} ->
        # Reload ownership changes for the updated round before returning
        updated_round = Repo.preload(updated_round, :ownership_changes)
        {:ok, updated_round}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Asynchronously regenerates the outcome for a specific round using the LLM stream.

  Returns `{:ok, stream_id, target_round}` on success, where `stream_id` can be used
  to track the streaming progress.
  """
  @spec regenerate_round_outcome_async(Ecto.UUID.t()) ::
          {:ok, String.t(), Round.t()} | {:error, any()}
  def regenerate_round_outcome_async(round_id) do
    # Use get_round to handle nil case gracefully
    with %Round{} = target_round <- Games.get_round(round_id),
         target_round <- Repo.preload(target_round, :game),
         %Game{} = game <- target_round.game,
         true <- game.is_training_example,
         # Load game state *before* this round's outcome was applied
         {:ok, %{game_state: game_state_before_outcome}} <-
           GameService.load_game(game.id, before_round_id: round_id) do
      # Determine provider
      provider_module = GameService.determine_provider(game)
      system_prompt = GameService.get_custom_prompt(game, :outcome)
      scenario_context = build_scenario_context(target_round)

      # Call the async version which uses LLMStreamService
      case provider_module.generate_outcome_async(
             game_state_before_outcome,
             # Pass game_id for streaming topic
             game.id,
             scenario_context,
             target_round.player_input,
             system_prompt
           ) do
        {:ok, stream_id} ->
          # Return stream_id and the round being regenerated
          {:ok, stream_id, target_round}

        {:error, reason} ->
          Logger.error("LLM outcome regeneration async call failed: #{inspect(reason)}")
          {:error, :llm_async_call_failed}
      end
    else
      false -> {:error, :not_a_training_game}
      # More specific error
      nil -> {:error, :round_not_found}
      # Error from load_game
      {:error, reason} -> {:error, reason}
    end
  end

  # --- Private Helpers ---

  # Builds the scenario context map needed by generate_outcome
  # (Copied from previous attempt, might need adjustment based on GameState structure)
  defp build_scenario_context(%Round{} = round) do
    if round.situation do
      %Scenario{
        id: "round_#{round.id}",
        situation: round.situation,
        # Assuming type isn't critical for regeneration
        type: :other
      }
    else
      # It was an 'acting' round with no preceding situation
      nil
    end
  end

  @doc """
  Updates a specific round with the final regenerated outcome data, including ownership changes.
  Called by the LiveView once the stream completes successfully.
  Uses a transaction to ensure atomicity.
  """
  @spec finalize_regenerated_outcome(Ecto.UUID.t(), Scenario.outcome()) ::
          {:ok, Round.t()} | {:error, Ecto.Changeset.t() | atom() | any()}
  def finalize_regenerated_outcome(round_id, outcome_data) do
    # Fetch round and preload game for ownership update
    target_round = Games.get_round!(round_id) |> Repo.preload(:game)
    game = target_round.game

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:round, fn _repo, _changes ->
        # Update basic round fields
        update_attrs =
          Map.take(outcome_data, [:cash_change, :burn_rate_change])
          |> Map.put(:outcome, outcome_data.text)

        Games.update_round(target_round, update_attrs)
      end)
      |> Ecto.Multi.run(:ownerships, fn _repo, %{round: updated_round_record} ->
        # Update ownership structure if changes are present in the outcome
        raw_ownership_changes = outcome_data.ownership_changes

        if raw_ownership_changes && is_list(raw_ownership_changes) do
          # Sanitize the list to ensure correct structure and atom keys
          sanitized_changes = sanitize_ownership_changes(raw_ownership_changes)
          # Pass the updated round record from the previous step
          # Use new function
          Games.apply_ownership_changes(sanitized_changes, game, updated_round_record)
        else
          # No ownership changes to process
          {:ok, nil}
        end
      end)

    case Repo.transaction(multi) do
      {:ok, %{round: updated_round}} ->
        # Preload changes again for the return value
        {:ok, Repo.preload(updated_round, :ownership_changes)}

      {:error, :round, changeset, _changes} ->
        {:error, changeset}

      {:error, :ownerships, reason, _changes} ->
        Logger.error("Error updating ownership structure during regeneration: #{inspect(reason)}")

        {:error, :ownership_update_failed}

      # Catch-all for other transaction errors
      {:error, failed_operation, failed_value, _changes} ->
        Logger.error(
          "Transaction failed during finalize_regenerated_outcome. Operation: #{failed_operation}, Value: #{inspect(failed_value)}"
        )

        {:error, :transaction_failed}
    end
  end

  # Closes finalize_regenerated_outcome/2

  # --- Sanitization Helpers (defined inside TrainingGames) ---

  # Takes a list of maps (potentially with string keys from JSON) and returns
  # a list of maps with atom keys and validated change_type.
  defp sanitize_ownership_changes(raw_changes) when is_list(raw_changes) do
    Enum.map(raw_changes, &sanitize_single_ownership_change/1)
    # Filter out invalid entries
    |> Enum.reject(&is_nil(&1))
  end

  # Sanitizes a single ownership change map. Returns nil if invalid.
  defp sanitize_single_ownership_change(map) when is_map(map) do
    # Explicitly extract values, checking both atom and string keys
    entity_name = map[:entity_name] || map["entity_name"]
    percentage = map[:percentage] || map["percentage"]
    previous_percentage = map[:previous_percentage] || map["previous_percentage"]
    raw_change_type = map[:change_type] || map["change_type"]

    # Validate and convert change_type
    change_type =
      case to_string(raw_change_type) do
        "investment" -> :investment
        "dilution" -> :dilution
        "exit" -> :exit
        "initial" -> :initial
        _ -> nil
      end

    # Only return a map if the change_type is valid
    if change_type do
      %{
        entity_name: entity_name,
        # Rename key to match what apply_ownership_changes expects
        new_percentage: percentage,
        previous_percentage: previous_percentage,
        change_type: change_type
      }
    else
      # Indicate invalid entry
      nil
    end
  end

  # Fallback for non-map elements in the list
  defp sanitize_single_ownership_change(_), do: nil
end

# Closes StartupGame.TrainingGames module
