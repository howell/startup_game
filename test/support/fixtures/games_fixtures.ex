defmodule StartupGame.GamesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `StartupGame.Games` and `StartupGame.GameService` contexts.
  """

  alias StartupGame.GameService
  alias StartupGame.Games
  alias StartupGame.Engine.Demo.StaticScenarioProvider
  alias StartupGame.AccountsFixtures

  @doc """
  Creates a game with default values.
  """
  def game_fixture(attrs \\ %{}, user \\ nil) do
    user = user || AccountsFixtures.user_fixture()

    {:ok, %{game: game}} =
      GameService.start_game(
        attrs[:name] || "Test Startup",
        attrs[:description] || "A test startup company",
        user,
        attrs[:provider] || StaticScenarioProvider
      )

    # If specific financial values were provided, update the game
    game = if attrs[:cash_on_hand] || attrs[:burn_rate] do
      {:ok, updated_game} = Games.update_game(game, %{
        cash_on_hand: attrs[:cash_on_hand] || game.cash_on_hand,
        burn_rate: attrs[:burn_rate] || game.burn_rate
      })
      updated_game
    else
      game
    end

    game
  end

  @doc """
  Creates a game with a specific status.
  """
  def game_fixture_with_status(status, attrs \\ %{}, user \\ nil) do
    game = game_fixture(attrs, user)

    {:ok, updated_game} =
      case status do
        :completed ->
          exit_type = attrs[:exit_type] || :acquisition
          exit_value = attrs[:exit_value] || Decimal.new("1000000.00")
          Games.complete_game(game, exit_type, exit_value)

        :failed ->
          Games.fail_game(game, attrs[:exit_type] || :shutdown)

        _ ->
          {:ok, game}
      end

    updated_game
  end

  @doc """
  Creates a game with multiple rounds.
  """
  def game_fixture_with_rounds(round_count \\ 3, attrs \\ %{}, user \\ nil) do
    game = game_fixture(attrs, user)

    # Process multiple responses to create rounds
    Enum.reduce(1..round_count, game, fn i, game ->
      {:ok, %{game: updated_game}} =
        GameService.process_response(game.id, "Response for round #{i}")

      updated_game
    end)
  end

  @doc """
  Creates a round for a game.
  """
  def round_fixture(game, attrs \\ %{}) do
    attrs = Map.merge(%{
      situation: "Test situation",
      game_id: game.id
    }, attrs)

    {:ok, round} = Games.create_round(attrs)
    round
  end

  @doc """
  Creates an ownership for a game.
  """
  def ownership_fixture(game, attrs \\ %{}) do
    attrs = Map.merge(%{
      entity_name: "Test Entity",
      percentage: Decimal.new("25.0"),
      game_id: game.id
    }, attrs)

    {:ok, ownership} = Games.create_ownership(attrs)
    ownership
  end

  @doc """
  Creates an ownership change for a game and round.
  """
  def ownership_change_fixture(game, round, attrs \\ %{}) do
    attrs = Map.merge(%{
      entity_name: "Test Entity",
      previous_percentage: Decimal.new("20.0"),
      new_percentage: Decimal.new("25.0"),
      change_type: :investment,
      game_id: game.id,
      round_id: round.id
    }, attrs)

    {:ok, ownership_change} = Games.create_ownership_change(attrs)
    ownership_change
  end

  @doc """
  Creates a game with a complete game state including rounds and ownerships.
  """
  def complete_game_fixture(attrs \\ %{}, user \\ nil) do
    user = user || AccountsFixtures.user_fixture()
    game = game_fixture(attrs, user)

    # Create additional ownerships
    ownership_fixture(game, %{entity_name: "Investor A", percentage: Decimal.new("15.0")})
    ownership_fixture(game, %{entity_name: "Investor B", percentage: Decimal.new("10.0")})

    # Create additional rounds
    round1 = round_fixture(game, %{
      situation: "First scenario",
      response: "First response",
      outcome: "First outcome"
    })

    round2 = round_fixture(game, %{
      situation: "Second scenario",
      response: "Second response",
      outcome: "Second outcome",
      cash_change: Decimal.new("5000.00"),
      burn_rate_change: Decimal.new("500.00")
    })

    # Create ownership changes
    ownership_change_fixture(game, round1, %{
      entity_name: "Founder",
      previous_percentage: Decimal.new("100.0"),
      new_percentage: Decimal.new("75.0"),
      change_type: :dilution
    })

    ownership_change_fixture(game, round2, %{
      entity_name: "Investor A",
      previous_percentage: Decimal.new("0.0"),
      new_percentage: Decimal.new("15.0"),
      change_type: :investment
    })

    # Return the game with all associations
    Games.get_game_with_associations!(game.id)
  end
end
