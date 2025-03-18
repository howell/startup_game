defmodule StartupGame.CLI.Utils do
  @moduledoc """
  Utilities for handling input and output in the command-line interface.
  """

  alias StartupGame.Engine.GameState
  alias StartupGame.Engine.Demo.{StaticScenarioProvider, DynamicScenarioProvider}
  alias StartupGame.Engine.GameRunner

  @doc """
  Displays the welcome message for the CLI.
  """
  @spec display_welcome() :: :ok
  def display_welcome do
    IO.puts("\n=== Startup Game CLI ===\n")
    IO.puts("Welcome to the Startup Game! Run your own startup and see if you can succeed.")

    IO.puts(
      "You'll face various scenarios and make decisions that affect your company's future.\n"
    )
  end

  @doc """
  Displays the goodbye message when exiting the CLI.
  """
  @spec display_goodbye() :: :ok
  def display_goodbye do
    IO.puts("\nThanks for playing the Startup Game! Goodbye.\n")
  end

  @doc """
  Displays the current game state with financial and ownership information.
  """
  @spec display_game_state(GameState.t()) :: :ok
  def display_game_state(game_state) do
    IO.puts("\n=== Game State: #{game_state.name} ===")
    IO.puts("Cash: $#{game_state.cash_on_hand} | Burn Rate: $#{game_state.burn_rate}/month")

    runway = GameState.calculate_runway(game_state)
    IO.puts("Runway: #{runway} months")

    IO.puts("Ownership:")

    Enum.each(game_state.ownerships, fn ownership ->
      IO.puts("  #{ownership.entity_name}: #{ownership.percentage}%")
    end)

    IO.puts("")
  end

  @doc """
  Displays the current scenario situation.
  """
  @spec display_situation(map()) :: :ok
  def display_situation(situation) do
    IO.puts("--- Current Situation ---")
    IO.puts(situation.situation)
    IO.puts("")
  end

  @doc """
  Displays the outcome of the last round.
  """
  @spec display_outcome(GameState.t()) :: :ok
  def display_outcome(game_state) do
    # Return early if no rounds
    if Enum.empty?(game_state.rounds) do
      :ok
    else
      # Extract the last round
      last_round = List.last(game_state.rounds)

      IO.puts("\n--- Outcome ---")
      IO.puts(last_round.outcome)

      # Display financial changes
      display_cash_change(last_round.cash_change)
      display_burn_rate_change(last_round.burn_rate_change)

      IO.puts("")
      :ok
    end
  end

  # Helper to display cash change
  @spec display_cash_change(Decimal.t() | nil) :: :ok
  defp display_cash_change(nil), do: :ok

  defp display_cash_change(cash_change) do
    zero = Decimal.new("0")

    case Decimal.compare(cash_change, zero) do
      :eq -> :ok
      :gt -> IO.puts("\nYour cash increased by $#{Decimal.abs(cash_change)}")
      :lt -> IO.puts("\nYour cash decreased by $#{Decimal.abs(cash_change)}")
    end
  end

  # Helper to display burn rate change
  @spec display_burn_rate_change(Decimal.t() | nil) :: :ok
  defp display_burn_rate_change(nil), do: :ok

  defp display_burn_rate_change(burn_rate_change) do
    zero = Decimal.new("0")

    case Decimal.compare(burn_rate_change, zero) do
      :eq -> :ok
      :gt -> IO.puts("Your burn rate increased by $#{Decimal.abs(burn_rate_change)}/month")
      :lt -> IO.puts("Your burn rate decreased by $#{Decimal.abs(burn_rate_change)}/month")
    end
  end

  @doc """
  Displays the final game result.
  """
  @spec display_game_result(GameState.t()) :: :ok
  def display_game_result(game_state) do
    summary = GameRunner.get_game_summary(game_state)

    IO.puts("\n=== Game Over ===")
    IO.puts("Result: #{summary.result}")

    case summary do
      %{result: "In Progress"} ->
        IO.puts("The developer ran out of scenarios to continue the game.")

      %{exit_type: exit_type, exit_value: exit_value} when exit_type in [:acquisition, :ipo] ->
        IO.puts("Exit Type: #{exit_type}")
        IO.puts("Exit Value: $#{exit_value}")

      %{reason: reason} ->
        IO.puts("Reason: #{reason}")
    end

    IO.puts("Rounds Played: #{summary.rounds_played}")
    IO.puts("")
  end

  @doc """
  Gets the initial cash on hand value from the user.
  """
  @spec get_cash_input() :: Decimal.t()
  def get_cash_input do
    IO.puts("Enter initial cash on hand [10000.00]:")

    case IO.gets("> ") |> String.trim() do
      "" ->
        Decimal.new("10000.00")

      input ->
        case Decimal.parse(input) do
          {decimal, ""} ->
            decimal

          _ ->
            IO.puts("Invalid input. Please enter a valid number.")
            get_cash_input()
        end
    end
  end

  @doc """
  Gets the scenario provider selection from the user.
  """
  @spec get_provider_selection() :: module()
  def get_provider_selection do
    IO.puts("\nSelect a scenario provider:")
    IO.puts("1. Static Scenario Provider (fixed scenarios)")
    IO.puts("2. Dynamic Scenario Provider (varying scenarios)")

    case IO.gets("> ") |> String.trim() do
      "1" ->
        StaticScenarioProvider

      "2" ->
        DynamicScenarioProvider

      _ ->
        IO.puts("Invalid selection. Please try again.")
        get_provider_selection()
    end
  end

  @doc """
  Gets text input from the user with the given prompt.
  """
  @spec get_text_input(String.t()) :: String.t()
  def get_text_input(prompt) do
    IO.puts("\n#{prompt}:")

    case IO.gets("> ") |> String.trim() do
      "" ->
        IO.puts("Input cannot be empty. Please try again.")
        get_text_input(prompt)

      input ->
        input
    end
  end

  @doc """
  Gets the user's free-form text response to the current scenario.
  """
  @spec get_response(map()) :: String.t()
  def get_response(scenario) do
    # Get free-form text input from the user
    IO.puts("\nEnter your response:")

    case IO.gets("> ") |> String.trim() do
      "" ->
        IO.puts("Response cannot be empty. Please try again.")
        get_response(scenario)

      input ->
        input
    end
  end

  @doc """
  Asks if the user wants to play again and returns a boolean.
  """
  @spec play_again?() :: boolean()
  def play_again? do
    IO.puts("Would you like to play again? (y/n):")

    case IO.gets("> ") |> String.trim() |> String.downcase() do
      input when input in ["y", "yes"] ->
        true

      input when input in ["n", "no"] ->
        false

      _ ->
        IO.puts("Please enter 'y' or 'n'.")
        play_again?()
    end
  end
end
