defmodule StartupGame.Games do
  @moduledoc """
  The Games context.
  This context handles all operations related to games, rounds, ownerships, and ownership changes.
  """

  import Ecto.Query, warn: false
  alias StartupGame.Repo

  alias StartupGame.Games.Game
  alias StartupGame.Games.Round
  alias StartupGame.Games.Ownership
  alias StartupGame.Games.OwnershipChange
  alias StartupGame.Accounts.User

  # Game-related functions

  @doc """
  Returns the list of games.

  ## Examples

      iex> list_games()
      [%Game{}, ...]

  """
  def list_games do
    Repo.all(Game)
  end

  @doc """
  Returns the list of games for a specific user.

  ## Examples

      iex> list_user_games(user_id)
      [%Game{}, ...]

  """
  def list_user_games(user_id) do
    Game
    |> where([g], g.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Returns the list of public games eligible for the leaderboard.

  ## Examples

      iex> list_leaderboard_games()
      [%Game{}, ...]

  """
  def list_leaderboard_games do
    Game
    |> where([g], g.is_public == true and g.is_leaderboard_eligible == true)
    |> where([g], g.status == :completed)
    |> where([g], g.exit_type in [:acquisition, :ipo])
    |> order_by([g], desc: g.exit_value)
    |> limit(50)
    |> Repo.all()
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game!(123)
      %Game{}

      iex> get_game!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game!(id), do: Repo.get!(Game, id)

  @doc """
  Gets a single game with preloaded associations.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game_with_associations!(123)
      %Game{rounds: [...], ownerships: [...]}

  """
  def get_game_with_associations!(id) do
    Game
    |> Repo.get!(id)
    |> Repo.preload([:ownerships, rounds: from(r in Round, order_by: r.inserted_at)])
  end

  @doc """
  Gets a single game with preloaded associations, or `nil` if the Game does not exist.
  """
  @spec get_game_with_associations(Ecto.UUID.t()) :: Game.t() | nil
  def get_game_with_associations(id) do
    Game
    |> Repo.get(id)
    |> Repo.preload([:ownerships, rounds: from(r in Round, order_by: r.inserted_at)])
  end

  @doc """
  Creates a game.

  ## Examples

      iex> create_game(%{field: value})
      {:ok, %Game{}}

      iex> create_game(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a new game with initial ownership for the founder.

  ## Examples

      iex> create_new_game(%{name: "My Startup", description: "A cool app"}, user)
      {:ok, %Game{}}

  """
  def create_new_game(attrs, %User{} = user) do
    # Set default values for a new game
    attrs =
      Map.merge(
        %{
          # Starting with $10,000
          cash_on_hand: 10_000.0,
          # $1,000 per month burn rate
          burn_rate: 1_000.0,
          status: :in_progress,
          is_public: false,
          is_leaderboard_eligible: false,
          exit_value: 0,
          exit_type: :none,
          user_id: user.id
        },
        attrs
      )

    Repo.transaction(fn ->
      with {:ok, game} <- create_game(attrs),
           # Create initial ownership record (founder owns 100%)
           {:ok, _ownership} <-
             create_ownership(%{
               entity_name: "Founder",
               percentage: 100.0,
               game_id: game.id
             }) do
        game
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Updates a game.

  ## Examples

      iex> update_game(game, %{field: new_value})
      {:ok, %Game{}}

      iex> update_game(game, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a game.

  ## Examples

      iex> delete_game(game)
      {:ok, %Game{}}

      iex> delete_game(game)
      {:error, %Ecto.Changeset{}}

  """
  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{data: %Game{}}

  """
  def change_game(%Game{} = game, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end

  # Round-related functions

  @doc """
  Returns the list of rounds for a specific game.

  ## Examples

      iex> list_game_rounds(game_id)
      [%Round{}, ...]

  """
  def list_game_rounds(game_id) do
    Round
    |> where([r], r.game_id == ^game_id)
    |> order_by([r], asc: r.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single round.

  Raises `Ecto.NoResultsError` if the Round does not exist.

  ## Examples

      iex> get_round!(123)
      %Round{}

      iex> get_round!(456)
      ** (Ecto.NoResultsError)

  """
  def get_round!(id), do: Repo.get!(Round, id)

  @doc """
  Creates a round.

  ## Examples

      iex> create_round(%{field: value})
      {:ok, %Round{}}

      iex> create_round(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_round(attrs \\ %{}) do
    %Round{}
    |> Round.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a new round and updates the game state based on the round's outcome.

  ## Examples

      iex> create_game_round(%{situation: "Investor meeting"}, game)
      {:ok, %{round: %Round{}, game: %Game{}}}

  """
  def create_game_round(attrs, %Game{} = game) do
    Repo.transaction(fn ->
      attrs = Map.put(attrs, :game_id, game.id)

      case create_round(attrs) do
        {:ok, round} ->
          update_game_after_round(game, round)

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  # Helper function to update game state after a round
  defp update_game_after_round(game, round) do
    # Calculate new financial state
    new_cash = Decimal.add(game.cash_on_hand, round.cash_change || Decimal.new(0))
    new_burn_rate = Decimal.add(game.burn_rate, round.burn_rate_change || Decimal.new(0))

    # Calculate runway and determine game status
    runway = calculate_runway_from_values(new_cash, new_burn_rate)
    game_status = determine_game_status(new_cash, runway)

    # Update the game with new values
    {:ok, updated_game} =
      update_game(
        game,
        Map.merge(
          %{
            cash_on_hand: new_cash,
            burn_rate: new_burn_rate
          },
          game_status
        )
      )

    %{round: round, game: updated_game}
  end

  # Helper function to calculate runway from cash and burn rate values
  defp calculate_runway_from_values(cash, burn_rate) do
    if Decimal.compare(burn_rate, Decimal.new(0)) == :gt do
      Decimal.div(cash, burn_rate)
    else
      # Infinite runway if burn rate is 0 or negative
      Decimal.new(999)
    end
  end

  # Helper function to determine game status based on financial state
  defp determine_game_status(cash, runway) do
    cond do
      Decimal.compare(cash, Decimal.new(0)) == :lt ->
        %{status: :failed, exit_type: :shutdown}

      Decimal.compare(runway, Decimal.new(1)) == :lt ->
        %{status: :failed, exit_type: :shutdown}

      true ->
        # No change to status
        %{}
    end
  end

  @doc """
  Updates a round.

  ## Examples

      iex> update_round(round, %{field: new_value})
      {:ok, %Round{}}

      iex> update_round(round, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_round(%Round{} = round, attrs) do
    round
    |> Round.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a round.

  ## Examples

      iex> delete_round(round)
      {:ok, %Round{}}

      iex> delete_round(round)
      {:error, %Ecto.Changeset{}}

  """
  def delete_round(%Round{} = round) do
    Repo.delete(round)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking round changes.

  ## Examples

      iex> change_round(round)
      %Ecto.Changeset{data: %Round{}}

  """
  def change_round(%Round{} = round, attrs \\ %{}) do
    Round.changeset(round, attrs)
  end

  # Ownership-related functions

  @doc """
  Returns the list of ownerships for a specific game.

  ## Examples

      iex> list_game_ownerships(game_id)
      [%Ownership{}, ...]

  """
  def list_game_ownerships(game_id) do
    Ownership
    |> where([o], o.game_id == ^game_id)
    |> Repo.all()
  end

  @doc """
  Gets a single ownership.

  Raises `Ecto.NoResultsError` if the Ownership does not exist.

  ## Examples

      iex> get_ownership!(123)
      %Ownership{}

      iex> get_ownership!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ownership!(id), do: Repo.get!(Ownership, id)

  @doc """
  Creates an ownership.

  ## Examples

      iex> create_ownership(%{field: value})
      {:ok, %Ownership{}}

      iex> create_ownership(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ownership(attrs \\ %{}) do
    %Ownership{}
    |> Ownership.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an ownership.

  ## Examples

      iex> update_ownership(ownership, %{field: new_value})
      {:ok, %Ownership{}}

      iex> update_ownership(ownership, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ownership(%Ownership{} = ownership, attrs) do
    ownership
    |> Ownership.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an ownership.

  ## Examples

      iex> delete_ownership(ownership)
      {:ok, %Ownership{}}

      iex> delete_ownership(ownership)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ownership(%Ownership{} = ownership) do
    Repo.delete(ownership)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ownership changes.

  ## Examples

      iex> change_ownership(ownership)
      %Ecto.Changeset{data: %Ownership{}}

  """
  def change_ownership(%Ownership{} = ownership, attrs \\ %{}) do
    Ownership.changeset(ownership, attrs)
  end

  # OwnershipChange-related functions

  @doc """
  Returns the list of ownership changes for a specific game.

  ## Examples

      iex> list_game_ownership_changes(game_id)
      [%OwnershipChange{}, ...]

  """
  def list_game_ownership_changes(game_id) do
    OwnershipChange
    |> where([oc], oc.game_id == ^game_id)
    |> order_by([oc], asc: oc.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns the list of ownership changes for a specific round.

  ## Examples

      iex> list_round_ownership_changes(round_id)
      [%OwnershipChange{}, ...]

  """
  def list_round_ownership_changes(round_id) do
    OwnershipChange
    |> where([oc], oc.round_id == ^round_id)
    |> Repo.all()
  end

  @doc """
  Gets a single ownership_change.

  Raises `Ecto.NoResultsError` if the OwnershipChange does not exist.

  ## Examples

      iex> get_ownership_change!(123)
      %OwnershipChange{}

      iex> get_ownership_change!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ownership_change!(id), do: Repo.get!(OwnershipChange, id)

  @doc """
  Creates an ownership_change.

  ## Examples

      iex> create_ownership_change(%{field: value})
      {:ok, %OwnershipChange{}}

      iex> create_ownership_change(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ownership_change(attrs \\ %{}) do
    %OwnershipChange{}
    |> OwnershipChange.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates ownership structure and records the changes.

  ## Examples

      iex> update_ownership_structure([%{entity_name: "Investor", percentage: 20}], game, round)
      {:ok, [%Ownership{}, ...]}

  """
  def update_ownership_structure(new_ownerships, %Game{} = game, %Round{} = round) do
    Repo.transaction(fn ->
      # Get current ownerships
      current_ownerships = list_game_ownerships(game.id)
      current_by_entity = ownership_map_by_entity(current_ownerships)

      # Process each new ownership
      results = process_new_ownerships(new_ownerships, current_by_entity, game, round)

      # Handle entities that are in current but not in new (they were removed)
      new_entity_names = Enum.map(new_ownerships, & &1.entity_name)
      remove_missing_entities(current_ownerships, new_entity_names, game, round)

      results
    end)
  end

  # Helper function to create a map of ownerships by entity name
  defp ownership_map_by_entity(ownerships) do
    Enum.reduce(ownerships, %{}, fn ownership, acc ->
      Map.put(acc, ownership.entity_name, ownership)
    end)
  end

  # Helper function to process new ownerships
  defp process_new_ownerships(new_ownerships, current_by_entity, game, round) do
    Enum.map(new_ownerships, fn %{entity_name: entity_name, percentage: percentage} ->
      case Map.get(current_by_entity, entity_name) do
        nil ->
          create_new_entity_ownership(entity_name, percentage, game, round)

        existing ->
          update_existing_entity_ownership(existing, percentage, game, round)
      end
    end)
  end

  # Helper function to create a new entity ownership
  defp create_new_entity_ownership(entity_name, percentage, game, round) do
    {:ok, ownership} =
      create_ownership(%{
        entity_name: entity_name,
        percentage: percentage,
        game_id: game.id
      })

    {:ok, _change} =
      create_ownership_change(%{
        entity_name: entity_name,
        previous_percentage: 0,
        new_percentage: percentage,
        change_type: :initial,
        game_id: game.id,
        round_id: round.id
      })

    ownership
  end

  # Helper function to update an existing entity ownership
  defp update_existing_entity_ownership(existing, percentage, game, round) do
    if Decimal.compare(existing.percentage, percentage) != :eq do
      {:ok, ownership} = update_ownership(existing, %{percentage: percentage})

      change_type =
        if Decimal.compare(existing.percentage, percentage) == :lt do
          :investment
        else
          :dilution
        end

      {:ok, _change} =
        create_ownership_change(%{
          entity_name: existing.entity_name,
          previous_percentage: existing.percentage,
          new_percentage: percentage,
          change_type: change_type,
          game_id: game.id,
          round_id: round.id
        })

      ownership
    else
      existing
    end
  end

  # Helper function to remove entities that are no longer present
  defp remove_missing_entities(current_ownerships, new_entity_names, game, round) do
    Enum.each(current_ownerships, fn ownership ->
      unless Enum.member?(new_entity_names, ownership.entity_name) do
        {:ok, _change} =
          create_ownership_change(%{
            entity_name: ownership.entity_name,
            previous_percentage: ownership.percentage,
            new_percentage: 0,
            change_type: :exit,
            game_id: game.id,
            round_id: round.id
          })

        {:ok, _} = delete_ownership(ownership)
      end
    end)
  end

  @doc """
  Updates an ownership_change.

  ## Examples

      iex> update_ownership_change(ownership_change, %{field: new_value})
      {:ok, %OwnershipChange{}}

      iex> update_ownership_change(ownership_change, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ownership_change(%OwnershipChange{} = ownership_change, attrs) do
    ownership_change
    |> OwnershipChange.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an ownership_change.

  ## Examples

      iex> delete_ownership_change(ownership_change)
      {:ok, %OwnershipChange{}}

      iex> delete_ownership_change(ownership_change)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ownership_change(%OwnershipChange{} = ownership_change) do
    Repo.delete(ownership_change)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ownership_change changes.

  ## Examples

      iex> change_ownership_change(ownership_change)
      %Ecto.Changeset{data: %OwnershipChange{}}

  """
  def change_ownership_change(%OwnershipChange{} = ownership_change, attrs \\ %{}) do
    OwnershipChange.changeset(ownership_change, attrs)
  end

  # Game state functions

  @doc """
  Calculates the current runway (months of cash left) for a game.

  ## Examples

      iex> calculate_runway(game)
      12.5

  """
  def calculate_runway(%Game{} = game) do
    if Decimal.compare(game.burn_rate, Decimal.new(0)) == :gt do
      Decimal.div(game.cash_on_hand, game.burn_rate)
    else
      # Infinite runway if burn rate is 0 or negative
      Decimal.new(999)
    end
  end

  @doc """
  Completes a game with an exit (acquisition or IPO).

  ## Examples

      iex> complete_game(game, :acquisition, 1000000)
      {:ok, %Game{}}

  """
  def complete_game(%Game{} = game, exit_type, exit_value)
      when exit_type in [:acquisition, :ipo] do
    update_game(game, %{
      status: :completed,
      exit_type: exit_type,
      exit_value: exit_value
    })
  end

  @doc """
  Fails a game (bankruptcy or shutdown).

  ## Examples

      iex> fail_game(game, :shutdown)
      {:ok, %Game{}}

  """
  def fail_game(%Game{} = game, exit_type \\ :shutdown) when exit_type in [:shutdown] do
    update_game(game, %{
      status: :failed,
      exit_type: exit_type
    })
  end
end
