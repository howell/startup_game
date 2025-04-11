defmodule StartupGame.TrainingGames do
  @moduledoc """
  Context module for managing training game data and operations,
  like regenerating outcomes.
  """

  alias StartupGame.Games
  alias StartupGame.Games.{Game, Round}
  alias StartupGame.GameService
  # alias StartupGame.Engine.GameState # Unused
  # Needed for Outcome map type below
  alias StartupGame.Engine.Scenario
  # alias StartupGame.Engine.Scenario.Outcome # Not a struct

  require Logger

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
         %Game{} = game <- Games.get_game_with_associations!(target_round.game_id),
         # Ensure it's a training game
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
  Updates a specific round with the final regenerated outcome data.
  Called by the LiveView once the stream completes successfully.
  """
  @spec finalize_regenerated_outcome(Ecto.UUID.t(), Scenario.outcome()) ::
          {:ok, Round.t()} | {:error, Ecto.Changeset.t()}
  # Expect a map, not a struct
  def finalize_regenerated_outcome(round_id, %{} = outcome_data) do
    target_round = Games.get_round!(round_id)

    update_attrs = %{
      outcome: outcome_data.narrative,
      cash_change: outcome_data.cash_change,
      burn_rate_change: outcome_data.burn_rate_change
      # TODO: Handle ownership/exit data persistence. This might require
      # loading the game, applying the outcome to the state, and then
      # saving the round AND the game's financial state, potentially
      # using a multi transaction like in GameService.save_round_result.
      # For now, only updating the round directly.
    }

    Games.update_round(target_round, update_attrs)
  end
end
