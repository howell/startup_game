defmodule StartupGame.GameService do
  @moduledoc """
  Service layer that connects the game engine with database persistence.

  This module provides functions to start, load, save, and process game actions,
  bridging the in-memory game state with the database records.
  """

  alias StartupGame.Engine.Scenario
  alias StartupGame.Engine
  alias StartupGame.Games
  alias StartupGame.Games.{Game, Round}
  alias StartupGame.Accounts.User
  alias StartupGame.Engine.GameState
  require Logger

  @type games() :: %{game: Game.t(), game_state: GameState.t()}
  @type game_result :: {:ok, games()} | {:error, any()}
  @type game_and_round_result() :: {:ok, games(), Round.t()} | {:error, any()}

  @doc """
  Creates a new game and persists it to the database without setting an initial scenario.
  This allows for more flexibility in testing and step-by-step initialization.

  ## Examples

      iex> GameService.create_game("TechNova", "AI-powered project management", user)
      {:ok, %{game: %Games.Game{}, game_state: %Engine.GameState{}}}

  """
  @spec create_game(String.t(), String.t(), User.t(), module() | nil, map(), Game.player_mode()) ::
          game_result()
  def create_game(
        name,
        description,
        %User{} = user,
        provider \\ StartupGame.Engine.LLMScenarioProvider,
        attrs \\ %{},
        initial_player_mode \\ :responding
      ) do
    # Create in-memory game state without initial scenario
    game_state =
      if provider do
        Engine.new_game(name, description, provider)
      else
        %GameState{
          name: name,
          description: description,
          ownerships: [%{entity_name: "Founder", percentage: Decimal.new("100.00")}]
        }
      end

    # Store provider preference as string
    provider_preference =
      if provider do
        Atom.to_string(provider)
      else
        nil
      end

    # Persist to database with additional attributes
    game_attrs =
      Map.merge(
        %{
          name: name,
          description: description,
          cash_on_hand: game_state.cash_on_hand,
          burn_rate: game_state.burn_rate,
          provider_preference: provider_preference,
          # Add initial mode
          current_player_mode: initial_player_mode,
          is_public: attrs[:is_public] || user.default_game_visibility == :public,
          is_leaderboard_eligible:
            attrs[:is_leaderboard_eligible] || user.default_game_visibility == :public
        },
        # Allow override
        Map.take(attrs, [:is_public, :is_leaderboard_eligible, :current_player_mode])
      )

    case Games.create_new_game(game_attrs, user) do
      {:ok, game} ->
        {:ok, %{game: game, game_state: game_state}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Starts a game by setting its initial scenario and creating the first round.
  This should be called after create_game if you want a fully initialized game.

  ## Examples

      iex> GameService.start_game(game_id)
      {:ok, %{game: %Games.Game{}, game_state: %Engine.GameState{}}}

  """
  @spec start_game(Ecto.UUID.t()) :: game_result()
  def start_game(game_id) do
    with {:ok, %{game: game, game_state: game_state}} <- load_game(game_id) do
      # Decide whether to start the first round based on initial mode
      if game.current_player_mode == :responding do
        request_next_scenario_async(game_id)
        # Note: The caller (e.g., LiveView) will need to handle the async result
        # Return the loaded state immediately
        {:ok, %{game: game, game_state: game_state}}
      else
        # Player starts in acting mode, no initial scenario needed
        {:ok, %{game: game, game_state: game_state}}
      end
    end
  end

  @doc """
  Creates and starts a new game in one operation.
  This combines create_game and start_game for backwards compatibility.

  ## Examples

      iex> GameService.create_and_start_game("TechNova", "AI-powered project management", user)
      {:ok, %{game: %Games.Game{}, game_state: %Engine.GameState{}}}
  """
  @spec create_and_start_game(String.t(), String.t(), User.t(), module()) :: game_result()
  def create_and_start_game(
        name,
        description,
        %User{} = user,
        provider \\ StartupGame.Engine.LLMScenarioProvider
      ) do
    with {:ok, %{game: game}} <- create_game(name, description, user, provider) do
      start_game(game.id)
    end
  end

  @doc """
  Loads a game from the database and creates an in-memory game state.

  ## Examples

      iex> GameService.load_game(game_id)
      {:ok, %{game: %Games.Game{}, game_state: %Engine.GameState{}}}

  """
  @spec load_game(Ecto.UUID.t()) :: game_result()
  def load_game(game_id) do
    case Games.get_game_with_associations(game_id) do
      %Games.Game{} = game ->
        game_state = build_game_state_from_db(game)

        {:ok, %{game: game, game_state: game_state}}

      nil ->
        {:error, "Game not found"}
    end
  end

  @doc """
  Processes a player input (response or action), updates the game state, and persists changes.
  Does NOT automatically trigger the next round.

  ## Examples

      iex> GameService.process_player_input(game_id, "I'll invest in marketing")
      {:ok, %{game: %Games.Game{}, game_state: %Engine.GameState{}}}

  """
  @spec process_player_input(Ecto.UUID.t(), String.t()) :: game_and_round_result()
  def process_player_input(game_id, player_input) do
    with {:ok, %{game: game, game_state: game_state}} <- load_game(game_id),
         last_round <- List.last(game.rounds),
         _ <- Games.update_round(last_round, %{player_input: player_input}),
         %Engine.GameState{error_message: nil} = updated_game_state <-
           Engine.process_player_input(game_state, player_input) do
      # Save the result, but don't trigger the next round here
      save_round_result(game, updated_game_state)
    else
      %Engine.GameState{error_message: msg} -> {:error, msg}
      error -> error
    end
  end

  @doc """
  Asynchronously processes a player input by streaming the LLM results for the outcome.
  Returns immediately with a stream_id that can be used to track progress and the Round
  that the input corresponds to.

  The LiveView can subscribe to "llm_stream:{game_id}" to receive updates.
  """
  @spec process_player_input_async(Ecto.UUID.t(), String.t()) ::
          {:ok, String.t(), Round.t()} | {:error, any()}
  def process_player_input_async(game_id, player_input) do
    with {:ok, %{game: game, game_state: game_state}} <- load_game(game_id),
         {:ok, round} <- persist_player_input(game, player_input),
         provider = determine_provider(game),
         scenario_context = game_state.current_scenario_data,
         {:ok, stream_id} <-
           provider.generate_outcome_async(
             game_state,
             game_id,
             scenario_context,
             player_input
           ) do
      {:ok, stream_id, round}
    else
      {:error, reason} ->
        # Log the error or handle it as needed
        Logger.error("Failed to persist player input for game #{game_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Helper function to persist player input based on mode
  defp persist_player_input(%Game{} = game, player_input) do
    case game.current_player_mode do
      :responding ->
        # Find the last round and update it
        case List.last(game.rounds) do
          %Games.Round{} = last_round ->
            Games.update_round(last_round, %{player_input: player_input})

          nil ->
            # This shouldn't happen in responding mode if logic is correct
            Logger.error(
              "Attempted to update player input in :responding mode, but no last round found for game #{game.id}"
            )

            {:error, :no_round_found_in_responding_mode}
        end

      :acting ->
        # Create a new round
        Games.create_round(%{
          game_id: game.id,
          player_input: player_input,
          # No preceding situation in acting mode
          situation: nil
        })
    end
  end

  @doc """
  Asynchronously requests the next scenario by streaming the LLM results.
  Returns immediately with a stream_id that can be used to track progress.

  The LiveView can subscribe to "llm_stream:{game_id}" to receive updates.
  """
  @spec request_next_scenario_async(Ecto.UUID.t()) :: {:ok, String.t()} | {:error, any()}
  def request_next_scenario_async(game_id) do
    with {:ok, %{game: game, game_state: game_state}} <- load_game(game_id) do
      provider = determine_provider(game)
      provider.get_next_scenario_async(game_state, game.id, game_state.current_scenario)
    end
  end

  @doc """
  Finalizes a streamed outcome by saving it to the database.
  This is called once the complete outcome is received from the stream.
  Does NOT automatically start the next round.
  """
  @spec finalize_streamed_outcome(Ecto.UUID.t(), Scenario.outcome()) :: game_and_round_result()
  def finalize_streamed_outcome(game_id, outcome) do
    with {:ok, %{game: game, game_state: game_state}} <- load_game(game_id) do
      # Retrieve the player input that triggered this outcome from the last round record
      player_input = List.last(game.rounds).player_input

      # Apply the outcome to the in-memory state
      updated_game_state = Engine.apply_outcome(game_state, outcome, player_input)

      # Save the results to the database
      save_round_result(game, updated_game_state)
    end
  end

  # start_next_round_after_outcome/1 removed - logic moved to LiveView StreamHandler

  @doc """
  Finalizes a streamed scenario by creating a new round in the database.
  This is called once the complete scenario is received from the stream.
  """
  @spec finalize_streamed_scenario(Ecto.UUID.t(), Scenario.t()) :: game_and_round_result()
  def finalize_streamed_scenario(game_id, scenario) do
    with {:ok, %{game: game, game_state: game_state}} <- load_game(game_id) do
      # Update the in-memory game state with the new scenario
      updated_game_state = %{
        game_state
        | current_scenario: scenario.id,
          current_scenario_data: scenario
      }

      # Create a new round record in the database for this scenario
      {:ok, round} =
        Games.create_round(%{
          situation: scenario.situation,
          game_id: game.id
          # player_input and outcome will be filled later
        })

      # Return the updated game struct, the updated game state, and the newly created round
      {:ok,
       %{
         game: %Games.Game{game | rounds: game.rounds ++ [round]},
         game_state: updated_game_state
       }, round}
    end
  end

  @doc """
  Asynchronously recovers a missing outcome by restarting the streaming process.
  Requires the original player input that needs reprocessing.
  """
  @spec recover_missing_outcome_async(Ecto.UUID.t(), String.t()) ::
          {:ok, String.t()} | {:error, any()}
  def recover_missing_outcome_async(game_id, player_input) do
    with {:ok, %{game: game, game_state: game_state}} <- load_game(game_id) do
      provider = determine_provider(game)

      # Use the same async function as the normal flow
      provider.generate_outcome_async(
        game_state,
        game_id,
        # Pass current scenario context
        game_state.current_scenario_data,
        player_input
      )
    end
  end

  @doc """
  Updates the player mode for a given game.
  """
  @spec update_player_mode(Ecto.UUID.t(), String.t() | atom()) ::
          {:ok, Games.Game.t()} | {:error, any()}
  def update_player_mode(game_id, new_mode) do
    # Ensure mode is an atom for DB update if it's a string
    mode_atom = if is_binary(new_mode), do: String.to_existing_atom(new_mode), else: new_mode

    with %Games.Game{} = game <- Games.get_game_with_associations!(game_id) do
      Games.update_game(game, %{current_player_mode: mode_atom})
    end
  end

  # --- Private functions ---

  # Builds in-memory game state from database records
  @spec build_game_state_from_db(Games.Game.t()) :: GameState.t()
  defp build_game_state_from_db(game) do
    {current_scenario_id, current_scenario_data, previous_rounds} =
      determine_current_and_previous_rounds(game)

    %GameState{
      name: game.name,
      description: game.description,
      cash_on_hand: game.cash_on_hand,
      burn_rate: game.burn_rate,
      status: game.status,
      exit_type: game.exit_type,
      exit_value: game.exit_value,
      ownerships:
        Enum.map(game.ownerships, fn o ->
          %{entity_name: o.entity_name, percentage: o.percentage}
        end),
      # Note: This doesn't include the *very last* round if it's awaiting input
      rounds: previous_rounds,
      scenario_provider: determine_provider(game),
      current_scenario: current_scenario_id,
      current_scenario_data: current_scenario_data
      # error_message is transient, not loaded from DB
    }
  end

  @doc """
  Since the DB stores the current round as the last entry in the rounds list,
  we need to separate it from the previous rounds and determine the current scenario.
  """
  @spec determine_current_and_previous_rounds(Games.Game.t()) ::
          {String.t() | nil, Engine.Scenario.t() | nil, [GameState.round_entry()]}
  def determine_current_and_previous_rounds(game) do
    # Sort rounds by insertion order just in case
    db_rounds = game.rounds
    game_state_rounds = build_rounds_from_db(db_rounds)

    case {game.status, db_rounds} do
      # No rounds yet
      {_, []} ->
        {nil, nil, []}

      # Game in progress, check the last round
      {:in_progress, [_ | _] = all_db_rounds} ->
        last_db_round = List.last(all_db_rounds)

        # If the last round has no outcome yet, it represents the current scenario
        if is_nil(last_db_round.outcome) do
          current_scenario_id = "round_#{last_db_round.id}"

          current_scenario_data = %Engine.Scenario{
            id: current_scenario_id,
            situation: last_db_round.situation,
            # Type might need to be inferred or stored if important
            type: :other
          }

          # Previous rounds are all but the last one
          # Use explicit step (fixed slice syntax)
          previous_rounds = List.delete_at(game_state_rounds, -1)

          {current_scenario_id, current_scenario_data, previous_rounds}
        else
          # Last round is complete, no current scenario active (player should be in 'acting' mode or game ended)
          {nil, nil, game_state_rounds}
        end

      # Game finished, all rounds are previous rounds
      # Prefix unused variable
      {_, _all_db_rounds} ->
        {nil, nil, game_state_rounds}
    end
  end

  # Converts database rounds to in-memory rounds format
  @spec build_rounds_from_db([Games.Round.t()]) :: [GameState.round_entry()]
  defp build_rounds_from_db(db_rounds) do
    Enum.map(db_rounds, fn round ->
      %{
        # Generate a scenario ID based on round ID
        scenario_id: "round_#{round.id}",
        situation: round.situation,
        # Use renamed field
        player_input: round.player_input,
        outcome: round.outcome,
        cash_change: round.cash_change,
        burn_rate_change: round.burn_rate_change,
        ownership_changes: determine_ownership_changes(round)
      }
    end)
  end

  @spec determine_ownership_changes(Games.Round.t()) :: [GameState.ownership_change()] | nil
  defp determine_ownership_changes(round) do
    if Ecto.assoc_loaded?(round.ownership_changes) do
      Enum.map(round.ownership_changes, fn oc ->
        %{
          entity_name: oc.entity_name,
          percentage_delta: oc.percentage_delta
        }
      end)
    else
      nil
    end
  end

  # Determines which scenario provider to use
  @spec determine_provider(Games.Game.t()) :: module()
  defp determine_provider(game) do
    case game.provider_preference do
      # Default to LLMScenarioProvider if no preference is set
      nil ->
        StartupGame.Engine.LLMScenarioProvider

      # Convert the string to a module atom
      provider_string when is_binary(provider_string) ->
        try do
          String.to_existing_atom(provider_string)
        rescue
          ArgumentError ->
            # Fallback if atom conversion fails (e.g., invalid preference string)
            Logger.warning(
              "Invalid provider preference '#{provider_string}', falling back to default."
            )

            StartupGame.Engine.LLMScenarioProvider
        end
    end
  end

  @doc """
  Saves the result of the last round to the database.

  Initiates a transaction that combines the following operations:
  1. Updating the last round with outcome data
  2. Processing any ownership changes
  3. Updating game finances
  """
  @spec save_round_result(Games.Game.t(), GameState.t()) :: game_and_round_result()
  def save_round_result(game, %GameState{} = game_state) do
    Ecto.Multi.new()
    |> save_last_round(game, game_state)
    |> update_finances(game, game_state)
    |> StartupGame.Repo.transaction()
    |> handle_transaction_result(game_state)
  end

  @spec handle_transaction_result(
          {:ok, map()} | {:error, any(), any(), any()},
          GameState.t()
        ) :: game_and_round_result()
  # Handles a successful transaction result
  defp handle_transaction_result(
         {:ok, %{game: updated_game, preloaded_round: updated_round}},
         game_state
       ) do
    {:ok, %{game: updated_game, game_state: game_state}, updated_round}
  end

  # Handles a failed transaction result
  defp handle_transaction_result({:error, _operation, reason, _changes}, _game_state) do
    {:error, reason}
  end

  # Adds steps to save the last round to the transaction.
  # Returns the Multi unchanged if there are no rounds.
  #
  # Contributes the following keys to the transaction:
  # - `:round` - The updated round record
  # - `:ownership_updates` - Results from updating ownership structure, or nil if no changes
  # - `:preloaded_round` - The final round with preloaded ownership_changes
  @spec save_last_round(Ecto.Multi.t(), Games.Game.t(), GameState.t()) :: Ecto.Multi.t()
  defp save_last_round(multi, _game, %GameState{rounds: []}), do: multi

  defp save_last_round(multi, game, game_state) do
    round_record = List.last(game.rounds)
    last_gs_round = List.last(game_state.rounds)

    if round_record do
      multi
      |> update_round_with_outcome(round_record, last_gs_round)
      |> process_ownership_updates(game, game_state, last_gs_round)
      |> preload_final_round()
    else
      Logger.error("Round record not found for game state round: #{inspect(last_gs_round)}")
      Ecto.Multi.error(multi, :round_mismatch, "Round record not found")
    end
  end

  # Updates the round record with outcome details from the game state.
  #
  # Contributes to the transaction:
  # - `:round` - The updated round record with outcome data
  @spec update_round_with_outcome(Ecto.Multi.t(), Round.t(), GameState.round_entry()) ::
          Ecto.Multi.t()
  defp update_round_with_outcome(multi, round, game_state_round) do
    round_updates = %{
      player_input: game_state_round.player_input,
      outcome: game_state_round.outcome,
      cash_change: game_state_round.cash_change,
      burn_rate_change: game_state_round.burn_rate_change
    }

    Ecto.Multi.run(multi, :round, fn _repo, _changes ->
      Games.update_round(round, round_updates)
    end)
  end

  # Processes and persists ownership changes that occurred during the round.
  #
  # Depends on:
  # - `:round` - The updated round from previous step
  #
  # Contributes to the transaction:
  # - `:ownership_updates` - Contains the result of Games.update_ownership_structure:
  #     - If changes exist: %{game: updated_game, round: updated_round, ownerships: updated_ownerships}
  #     - If no changes: nil
  @spec process_ownership_updates(
          Ecto.Multi.t(),
          Game.t(),
          GameState.t(),
          GameState.round_entry()
        ) ::
          Ecto.Multi.t()
  defp process_ownership_updates(multi, game, game_state, game_state_round) do
    Ecto.Multi.run(multi, :ownership_updates, fn _repo, %{round: updated_round} ->
      if game_state_round.ownership_changes do
        new_ownerships = extract_game_state_ownerships(game_state)
        Games.update_ownership_structure(new_ownerships, game, updated_round)
      else
        {:ok, nil}
      end
    end)
  end

  # Extracts ownership information from the game state.
  @spec extract_game_state_ownerships(GameState.t()) :: [
          %{entity_name: String.t(), percentage: Decimal.t()}
        ]
  defp extract_game_state_ownerships(%GameState{ownerships: ownerships}) do
    Enum.map(ownerships, fn %{entity_name: name, percentage: percentage} ->
      %{entity_name: name, percentage: percentage}
    end)
  end

  # Preloads the round with its associations for the final response.
  #
  # Depends on:
  # - `:round` - The updated round record
  # - `:ownership_updates` - Results from ownership update operation
  #
  # Contributes to the transaction:
  # - `:preloaded_round` - The final round with preloaded ownership_changes
  @spec preload_final_round(Ecto.Multi.t()) :: Ecto.Multi.t()
  defp preload_final_round(multi) do
    Ecto.Multi.run(multi, :preloaded_round, fn repo,
                                               %{
                                                 round: updated_round,
                                                 ownership_updates: ownership_result
                                               } ->
      round_to_preload = select_round_to_preload(ownership_result, updated_round)
      {:ok, repo.preload(round_to_preload, :ownership_changes)}
    end)
  end

  # Selects the appropriate round to preload based on ownership update results
  @spec select_round_to_preload(map() | nil, Round.t()) :: Round.t()
  defp select_round_to_preload(ownership_result, updated_round) do
    if ownership_result && Map.has_key?(ownership_result, :round) do
      ownership_result.round
    else
      updated_round
    end
  end

  # Updates the game's financial information based on the game state.
  #
  # Contributes to the transaction:
  # - `:game` - The updated game record with new financial data
  @spec update_finances(Ecto.Multi.t(), Games.Game.t(), GameState.t()) :: Ecto.Multi.t()
  defp update_finances(multi, game, %GameState{} = game_state) do
    changes = %{
      cash_on_hand: game_state.cash_on_hand,
      burn_rate: game_state.burn_rate,
      status: game_state.status,
      exit_type: game_state.exit_type,
      exit_value: game_state.exit_value
    }

    Ecto.Multi.update(multi, :game, Game.changeset(game, changes))
  end
end
