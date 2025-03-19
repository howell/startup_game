defmodule StartupGame.GameService do
  @moduledoc """
  Service layer that connects the game engine with database persistence.

  This module provides functions to start, load, save, and process game actions,
  bridging the in-memory game state with the database records.
  """

  alias StartupGame.Engine
  alias StartupGame.Games
  alias StartupGame.Accounts.User
  alias StartupGame.Engine.GameState

  @type game_result :: {:ok, %{game: Games.Game.t(), game_state: GameState.t()}} | {:error, any()}

  @doc """
  Starts a new game and persists it to the database.

  ## Examples

      iex> GameService.start_game("TechNova", "AI-powered project management", user)
      {:ok, %{game: %Games.Game{}, game_state: %Engine.GameState{}}}

  """
  @spec start_game(String.t(), String.t(), User.t(), module()) :: game_result
  def start_game(
        name,
        description,
        %User{} = user,
        provider \\ StartupGame.Engine.Demo.StaticScenarioProvider
      ) do
    # Create in-memory game state
    game_state = Engine.new_game(name, description, provider)

    # Persist to database
    case Games.create_new_game(
           %{
             name: name,
             description: description,
             cash_on_hand: game_state.cash_on_hand,
             burn_rate: game_state.burn_rate
           },
           user
         ) do
      {:ok, game} ->
        # Create the initial round with the first scenario
        scenario = game_state.current_scenario_data

        {:ok, _} =
          Games.create_round(%{
            situation: scenario.situation,
            game_id: game.id
          })

        {:ok, %{game: game, game_state: game_state}}

      {:error, reason} ->
        {:error, reason}
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
        rounds = Games.list_game_rounds(game_id)
        ownerships = Games.list_game_ownerships(game_id)

        # Recreate in-memory game state from database records
        game_state = build_game_state_from_db(game, rounds, ownerships)

        {:ok, %{game: game, game_state: game_state}}

      nil ->
        {:error, "Game not found"}
    end
  end

  @doc """
  Processes a player response, updates the game state, and persists changes to the database.

  ## Examples

      iex> GameService.process_response(game_id, "I'll invest in marketing")
      {:ok, %{game: %Games.Game{}, game_state: %Engine.GameState{}}}

  """
  @spec process_response(Ecto.UUID.t(), String.t()) :: game_result
  def process_response(game_id, response_text) do
    with {:ok, %{game: game, game_state: game_state}} <- load_game(game_id) do
      # Process the response in the game engine
      updated_game_state = Engine.process_response(game_state, response_text)

      # Persist changes to database
      save_game_state(game, updated_game_state, response_text)
    end
  end

  # Private functions

  # Builds in-memory game state from database records
  @spec build_game_state_from_db(Games.Game.t(), [Games.Round.t()], [Games.Ownership.t()]) ::
          GameState.t()
  defp build_game_state_from_db(game, rounds, ownerships) do
    # Create the base game state
    game_state = %GameState{
      name: game.name,
      description: game.description,
      cash_on_hand: game.cash_on_hand,
      burn_rate: game.burn_rate,
      status: game.status,
      exit_type: game.exit_type,
      exit_value: game.exit_value,
      ownerships:
        Enum.map(ownerships, fn o ->
          %{entity_name: o.entity_name, percentage: o.percentage}
        end),
      rounds: build_rounds_from_db(rounds),
      scenario_provider: determine_provider(game)
    }

    # Set current scenario or mark as completed/failed
    case game.status do
      :in_progress ->
        # Initialize provider and set current scenario
        provider = game_state.scenario_provider

        # Initialize with the appropriate scenario
        initial_scenario = provider.get_initial_scenario(game_state)

        %{
          game_state
          | current_scenario: initial_scenario.id,
            current_scenario_data: initial_scenario
        }

      _other ->
        # Game is already completed or failed
        game_state
    end
  end

  # Converts database rounds to in-memory rounds format
  @spec build_rounds_from_db([Games.Round.t()]) :: [GameState.round_entry()]
  defp build_rounds_from_db(rounds) do
    Enum.map(rounds, fn round ->
      %{
        # Generate a scenario ID based on round ID
        scenario_id: "round_#{round.id}",
        situation: round.situation,
        response: round.response,
        outcome: round.outcome,
        cash_change: round.cash_change,
        burn_rate_change: round.burn_rate_change,
        # Would need to load ownership_changes
        ownership_changes: nil
      }
    end)
  end

  # Determines which scenario provider to use
  @spec determine_provider(Games.Game.t()) :: module()
  defp determine_provider(_game) do
    # Logic to determine which provider to use
    # Could be stored in the database or determined by game type
    StartupGame.Engine.Demo.StaticScenarioProvider
  end

  # Persists game state changes to the database
  @spec save_game_state(Games.Game.t(), GameState.t(), String.t()) :: game_result
  defp save_game_state(game, game_state, response_text) do
    # Get the latest round (the one just processed)
    latest_round = List.last(game_state.rounds)

    Ecto.Multi.new()
    |> Ecto.Multi.run(:round, fn _repo, _changes ->
      # Create a new round record
      Games.create_round(%{
        situation: latest_round.situation,
        response: response_text,
        outcome: latest_round.outcome,
        cash_change: latest_round.cash_change,
        burn_rate_change: latest_round.burn_rate_change,
        game_id: game.id
      })
    end)
    |> Ecto.Multi.run(:game, fn _repo, %{round: round} ->
      # Update game financial state
      Games.update_game(game, %{
        cash_on_hand: game_state.cash_on_hand,
        burn_rate: game_state.burn_rate,
        status: game_state.status,
        exit_type: game_state.exit_type,
        exit_value: game_state.exit_value
      })
      |> case do
        {:ok, updated_game} -> {:ok, {updated_game, round}}
        error -> error
      end
    end)
    |> Ecto.Multi.run(:ownerships, fn _repo, %{game: {updated_game, round}} ->
      process_ownership_changes(
        latest_round.ownership_changes,
        game_state,
        updated_game,
        round
      )
    end)
    |> StartupGame.Repo.transaction()
    |> case do
      {:ok, %{game: {updated_game, _round}}} ->
        {:ok, %{game: updated_game, game_state: game_state}}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end

  defp process_ownership_changes(nil, _current_ownerships, _game, _round), do: {:ok, nil}

  defp process_ownership_changes(_changes, game_state, updated_game, round) do
    # Convert ownership_changes to database format
    new_ownerships =
      Enum.map(game_state.ownerships, fn o ->
        %{entity_name: o.entity_name, percentage: o.percentage}
      end)

    # Update ownership records
    Games.update_ownership_structure(new_ownerships, updated_game, round)
  end
end
