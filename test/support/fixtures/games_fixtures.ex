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
  Creates a game with default values and initializes it with a scenario.
  """
  def game_fixture(attrs \\ %{start?: true}, user \\ nil) do
    user = user || AccountsFixtures.user_fixture()

    {:ok, %{game: game}} =
      GameService.create_game(
        attrs[:name] || "Test Startup",
        attrs[:description] || "A test startup company",
        user,
        attrs[:provider] || StaticScenarioProvider,
        attrs,
        attrs[:player_mode] || :responding
      )

    game
    |> maybe_set_finances(attrs)
    |> maybe_start_game(attrs)
  end

  defp maybe_set_finances(game, attrs) do
    if attrs[:cash_on_hand] || attrs[:burn_rate] || attrs[:founder_return] ||
         attrs[:is_case_study] || Map.has_key?(attrs, :is_training_example) do
      {:ok, updated_game} =
        Games.update_game(game, %{
          cash_on_hand: attrs[:cash_on_hand] || game.cash_on_hand,
          burn_rate: attrs[:burn_rate] || game.burn_rate,
          founder_return: attrs[:founder_return] || game.founder_return,
          is_case_study: Map.get(attrs, :is_case_study, game.is_case_study),
          is_training_example: Map.get(attrs, :is_training_example, game.is_training_example)
        })

      updated_game
    else
      game
    end
  end

  defp maybe_start_game(game, attrs) do
    if attrs[:start?] do
      {:ok, %{game: updated_game}} = GameService.start_game(game.id)
      updated_game
    else
      game
    end
  end

  @doc """
  Creates a game with a specific status.
  """
  def game_fixture_with_status(status, attrs \\ %{}, user \\ nil) do
    game_fixture(attrs, user)
    |> complete_game(status, attrs)
  end

  def complete_game(game, status, attrs \\ %{}) do
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
  Creates a complete game with a specific founder ownership percentage.
  """
  def game_fixture_with_ownership(attrs \\ %{}, user \\ nil) do
    game = game_fixture(attrs, user)

    {:ok, ownership} =
      Games.update_ownership(hd(game.ownerships), %{
        percentage: attrs[:percentage] || Decimal.new("50.0")
      })

    %{game | ownerships: [ownership]}
    |> complete_game(attrs[:status] || :completed, attrs)
  end

  @doc """
  Creates a game with multiple rounds.
  """
  def game_fixture_with_rounds(round_count \\ 3, attrs \\ %{}, user \\ nil) do
    game = game_fixture(attrs, user)

    # Process multiple responses to create rounds
    # Directly create rounds instead of using GameService which has async dependencies
    Enum.reduce(1..round_count, game, fn i, current_game ->
      round_attrs = %{
        situation: "Situation for round #{i}",
        player_input: "Response for round #{i}",
        outcome: "Outcome for round #{i}",
        cash_change: Decimal.new(100 * i),
        burn_rate_change: Decimal.new(10 * i),
        game_id: current_game.id
      }
      # Use create_game_round to also update game finances based on round
      {:ok, %{game: updated_game}} = Games.create_game_round(round_attrs, current_game)
      updated_game
    end)
  end

  @doc """
  Creates a round for a game.
  """
  def round_fixture(game, attrs \\ %{}) do
    attrs =
      Map.merge(
        %{
          situation: "Test situation",
          game_id: game.id
        },
        attrs
      )

    {:ok, round} = Games.create_round(attrs)
    round
  end

  @doc """
  Creates an ownership for a game.
  """
  def ownership_fixture(game, attrs \\ %{}) do
    attrs =
      Map.merge(
        %{
          entity_name: "Test Entity",
          percentage: Decimal.new("25.0"),
          game_id: game.id
        },
        attrs
      )

    {:ok, ownership} = Games.create_ownership(attrs)
    ownership
  end

  @doc """
  Creates an ownership change for a game and round.
  """
  def ownership_change_fixture(game, round, attrs \\ %{}) do
    attrs =
      Map.merge(
        %{
          entity_name: "Test Entity",
          previous_percentage: Decimal.new("20.0"),
          new_percentage: Decimal.new("25.0"),
          change_type: :investment,
          game_id: game.id,
          round_id: round.id
        },
        attrs
      )

    {:ok, ownership_change} = Games.create_ownership_change(attrs)
    ownership_change
  end

  @doc """
  Creates a game with a complete game state including rounds and ownerships.
  """
  def complete_game_fixture(attrs \\ %{}, user \\ nil) do
    user = user || AccountsFixtures.user_fixture()
    game = game_fixture(Map.update(attrs, :start?, false, & &1), user)

    # Create additional ownerships
    ownership_fixture(game, %{entity_name: "Investor A", percentage: Decimal.new("15.0")})
    ownership_fixture(game, %{entity_name: "Investor B", percentage: Decimal.new("10.0")})

    # Create additional rounds
    round1 =
      round_fixture(game, %{
        situation: "First scenario",
        response: "First response",
        outcome: "First outcome"
      })

    round2 =
      round_fixture(game, %{
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
