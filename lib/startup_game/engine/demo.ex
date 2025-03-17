defmodule StartupGame.Engine.Demo do
  @moduledoc """
  Demonstration script for the simplified startup game engine.

  This module provides functions to run demo games and display the results
  in a readable format. It's useful for testing and demonstrating the engine.
  """

  alias StartupGame.Engine.GameRunner

  @doc """
  Runs a demo game with a predefined set of choices and prints the results.

  ## Examples

      iex> Demo.run()
      # Prints the game progress and results

  """
  def run do
    startup_name = "TechNova"
    startup_description = "AI-powered project management platform"

    IO.puts("\n=== Starting New Game: #{startup_name} ===")
    IO.puts("Description: #{startup_description}")

    # Start the game
    {game_state, situation} = GameRunner.start_game(startup_name, startup_description)

    # Display initial state
    display_game_state(game_state)
    display_situation(situation)

    # Make choices and display results
    choices = [
      {"accept", "Accept the angel investment offer"},
      {"experienced", "Hire the experienced developer"},
      {"settle", "Settle the lawsuit out of court"},
      {"counter", "Counter the acquisition offer"}
    ]

    final_state =
      Enum.reduce_while(choices, game_state, fn {choice_id, description}, state ->
        IO.puts("\n--- Player chooses: #{description} ---")

        {updated_state, next_situation} = GameRunner.make_choice(state, choice_id)
        display_game_state(updated_state)

        # Display the last round's outcome
        last_round = List.last(updated_state.rounds)
        IO.puts("Outcome: #{last_round.outcome}")

        if next_situation == nil do
          IO.puts("\n=== Game Over ===")
          {:halt, updated_state}
        else
          display_situation(next_situation)
          {:cont, updated_state}
        end
      end)

    # Display final summary
    summary = GameRunner.get_game_summary(final_state)
    display_summary(summary)

    final_state
  end

  @doc """
  Runs a demo game that fails due to running out of money.
  """
  def run_failure do
    startup_name = "CashBurn"
    startup_description = "Expensive hardware startup with no revenue model"

    IO.puts("\n=== Starting New Game: #{startup_name} ===")
    IO.puts("Description: #{startup_description}")

    # Start the game
    {game_state, situation} = GameRunner.start_game(startup_name, startup_description)

    # Display initial state
    display_game_state(game_state)
    display_situation(situation)

    # Make choices that lead to failure
    choices = [
      {"decline", "Decline the angel investment offer"},
      {"experienced", "Hire the experienced developer"},
      {"fight", "Fight the lawsuit"}
    ]

    final_state =
      Enum.reduce_while(choices, game_state, fn {choice_id, description}, state ->
        IO.puts("\n--- Player chooses: #{description} ---")

        {updated_state, next_situation} = GameRunner.make_choice(state, choice_id)
        display_game_state(updated_state)

        # Display the last round's outcome
        last_round = List.last(updated_state.rounds)
        IO.puts("Outcome: #{last_round.outcome}")

        if next_situation == nil do
          IO.puts("\n=== Game Over ===")
          {:halt, updated_state}
        else
          display_situation(next_situation)
          {:cont, updated_state}
        end
      end)

    # Display final summary
    summary = GameRunner.get_game_summary(final_state)
    display_summary(summary)

    final_state
  end

  # Helper functions for displaying game information

  defp display_game_state(game_state) do
    IO.puts("\nGame State:")
    IO.puts("  Cash on Hand: $#{game_state.cash_on_hand}")
    IO.puts("  Burn Rate: $#{game_state.burn_rate}/month")

    runway = StartupGame.Engine.GameState.calculate_runway(game_state)
    IO.puts("  Runway: #{runway} months")

    IO.puts("  Ownership:")

    Enum.each(game_state.ownerships, fn ownership ->
      IO.puts("    #{ownership.entity_name}: #{ownership.percentage}%")
    end)
  end

  defp display_situation(situation) do
    IO.puts("\nSituation:")
    IO.puts("  #{situation.situation}")

    IO.puts("\nChoices:")

    Enum.each(situation.choices, fn choice ->
      IO.puts("  #{choice.id}: #{choice.text}")
    end)
  end

  defp display_summary(summary) do
    IO.puts("\nGame Summary:")
    IO.puts("  Result: #{summary.result}")

    case summary do
      %{exit_type: exit_type, exit_value: exit_value} when exit_type in [:acquisition, :ipo] ->
        IO.puts("  Exit Type: #{exit_type}")
        IO.puts("  Exit Value: $#{exit_value}")

      %{reason: reason} ->
        IO.puts("  Reason: #{reason}")
    end

    IO.puts("  Rounds Played: #{summary.rounds_played}")
  end
end
