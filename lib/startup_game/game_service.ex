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
  Creates a new game and persists it to the database without setting an initial scenario.
  This allows for more flexibility in testing and step-by-step initialization.

  ## Examples

      iex> GameService.create_game("TechNova", "AI-powered project management", user)
      {:ok, %{game: %Games.Game{}, game_state: %Engine.GameState{}}}

  """
  @spec create_game(String.t(), String.t(), User.t(), module() | nil) :: game_result
  def create_game(
        name,
        description,
        %User{} = user,
        provider \\ StartupGame.Engine.LLMScenarioProvider
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

    # Persist to database
    case Games.create_new_game(
           %{
             name: name,
             description: description,
             cash_on_hand: game_state.cash_on_hand,
             burn_rate: game_state.burn_rate,
             provider_preference: provider_preference
           },
           user
         ) do
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
      start_next_round(game, game_state)
    end
  end

  @doc """
  Creates and starts a new game in one operation.
  This combines create_game and start_game for backwards compatibility.

  ## Examples

      iex> GameService.create_and_start_game("TechNova", "AI-powered project management", user)
      {:ok, %{game: %Games.Game{}, game_state: %Engine.GameState{}}}
  """
  @spec create_and_start_game(String.t(), String.t(), User.t(), module()) :: game_result
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
        ownerships = Games.list_game_ownerships(game_id)

        # Recreate in-memory game state from database records
        game_state = build_game_state_from_db(game, ownerships)

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
  @spec process_response(Ecto.UUID.t(), String.t()) :: game_result()
  def process_response(game_id, response_text) do
    with {:ok, %{game: game, game_state: game_state}} <- load_game(game_id),
         %Engine.GameState{error_message: nil} = updated_game_state <-
           Engine.process_response(game_state, response_text),
         {:ok, %{game: updated_game, game_state: final_state}} <-
           save_round_result(game, updated_game_state) do
      handle_progress(updated_game, final_state)
    else
      %Engine.GameState{error_message: msg} -> {:error, msg}
      error -> error
    end
  end

  defp handle_progress(game, game_state) do
    if game_state.status == :in_progress do
      start_next_round(game, game_state)
    else
      {:ok, %{game: game, game_state: game_state}}
    end
  end

  @spec start_next_round(Games.Game.t(), GameState.t()) :: game_result()
  def start_next_round(game, game_state) do
    game_state = Engine.set_next_scenario(game_state)

    scenario = game_state.current_scenario_data

    if scenario do
      {:ok, round} =
        Games.create_round(%{
          situation: scenario.situation,
          game_id: game.id
        })

      {:ok, %{game: %Games.Game{game | rounds: game.rounds ++ [round]}, game_state: game_state}}
    else
      {:error, "Failed to generate next scenario"}
    end
  end

  # Private functions

  # Builds in-memory game state from database records
  @spec build_game_state_from_db(Games.Game.t(), [Games.Ownership.t()]) ::
          GameState.t()
  defp build_game_state_from_db(game, ownerships) do
    {current_scenario, current_scenario_data, previous_rounds} =
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
        Enum.map(ownerships, fn o ->
          %{entity_name: o.entity_name, percentage: o.percentage}
        end),
      rounds: previous_rounds,
      scenario_provider: determine_provider(game),
      current_scenario: current_scenario,
      current_scenario_data: current_scenario_data
    }
  end

  @doc """
  Since the DB stores the current round as the last entry in the rounds list,
  we need to separate it from the previous rounds and determine the current scenario.
  """
  @spec determine_current_and_previous_rounds(Games.Game.t()) ::
          {String.t() | nil, Engine.Scenario.t() | nil, [GameState.round_entry()]}
  def determine_current_and_previous_rounds(game) do
    game_rounds = build_rounds_from_db(game.rounds)

    case {game.status, game_rounds} do
      {_, []} ->
        {nil, nil, game_rounds}

      {:in_progress, _} ->
        last_round = List.last(game_rounds)

        {last_round.scenario_id,
         %Engine.Scenario{
           id: last_round.scenario_id,
           situation: last_round.situation,
           type: :other
         }, List.delete_at(game_rounds, -1)}

      _other ->
        {nil, nil, game_rounds}
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
  defp determine_provider(game) do
    case Application.get_env(:startup_game, :env, Mix.env()) do
      :prod ->
        # In production, always use LLMScenarioProvider
        StartupGame.Engine.LLMScenarioProvider

      _ ->
        # In development, check if a provider preference is stored for this game
        case game.provider_preference do
          nil ->
            # Default to LLMScenarioProvider if no preference is set
            StartupGame.Engine.LLMScenarioProvider

          provider when is_binary(provider) ->
            # Convert the string to a module atom
            String.to_existing_atom(provider)
        end
    end
  end

  # Save info from the lastest round to the database
  @spec save_round_result(Games.Game.t(), GameState.t()) :: game_result()
  def save_round_result(game, game_state) do
    Ecto.Multi.new()
    |> save_last_round(game, game_state)
    |> update_finances(game, game_state)
    |> StartupGame.Repo.transaction()
    |> case do
      {:ok, %{game: {updated_game, round}}} ->
        {:ok,
         %{
           game: replace_game_round(updated_game, round),
           game_state: game_state
         }}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end

  @spec replace_game_round(Games.Game.t(), GameState.round_entry()) :: Games.Game.t()
  defp replace_game_round(game, round) do
    Enum.find_index(game.rounds, fn r -> r.id == round.id end)
    |> case do
      nil ->
        game

      index ->
        %{game | rounds: List.replace_at(game.rounds, index, round)}
    end
  end

  @spec save_last_round(Ecto.Multi.t(), Games.Game.t(), GameState.t()) :: Ecto.Multi.t()
  defp save_last_round(multi, _game, %GameState{rounds: []}), do: multi

  defp save_last_round(multi, game, game_state) do
    round_record = List.last(game.rounds)
    last_round = List.last(game_state.rounds)

    Ecto.Multi.run(multi, :round, fn _repo, _changes ->
      Games.update_round(
        round_record,
        %{
          response: last_round.response,
          outcome: last_round.outcome,
          cash_change: last_round.cash_change,
          burn_rate_change: last_round.burn_rate_change,
          game_id: game.id
        }
      )
    end)
    |> Ecto.Multi.run(:ownerships, fn _repo, %{round: round} ->
      process_ownership_changes(
        last_round.ownership_changes,
        game,
        game_state,
        round
      )
    end)
  end

  defp process_ownership_changes(nil, _game, _game_state, _round), do: {:ok, nil}

  defp process_ownership_changes(_changes, game, game_state, round) do
    new_ownerships =
      Enum.map(game_state.ownerships, fn o ->
        %{entity_name: o.entity_name, percentage: o.percentage}
      end)

    Games.update_ownership_structure(new_ownerships, game, round)
  end

  @spec update_finances(Ecto.Multi.t(), Games.Game.t(), GameState.t()) :: Ecto.Multi.t()
  defp update_finances(multi, game, game_state) do
    Ecto.Multi.run(multi, :game, fn _repo, %{round: round} ->
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
  end
end
