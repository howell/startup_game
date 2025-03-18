defmodule StartupGame.CLI.Main do
  @moduledoc """
  Main entry point for the CLI version of the startup game.

  This module handles the setup process for a new game, including gathering
  initial settings from the user and starting the game loop.
  """

  alias StartupGame.CLI.{GameLoop, Utils}
  alias StartupGame.Engine

  @doc """
  Entry point for the CLI application.
  """
  @spec start() :: :ok
  def start do
    Utils.display_welcome()
    play_game_loop()
    :ok
  end

  # Main loop that handles playing games and asking to play again
  @spec play_game_loop() :: :ok
  defp play_game_loop do
    # Get initial settings
    settings = get_initial_settings()

    # Start a new game with these settings
    {game_state, initial_situation} = start_new_game(settings)

    # Run the game loop
    final_state = GameLoop.run(game_state, initial_situation)

    # Display final results
    Utils.display_game_result(final_state)

    # Ask if the user wants to play again
    if Utils.play_again?() do
      play_game_loop()
    else
      Utils.display_goodbye()
    end
  end

  # Collects initial settings from the user
  @spec get_initial_settings() :: %{
          cash_on_hand: Decimal.t(),
          provider: module(),
          name: String.t(),
          description: String.t()
        }
  defp get_initial_settings do
    # Get cash on hand
    cash_on_hand = Utils.get_cash_input()

    # Get scenario provider
    provider = Utils.get_provider_selection()

    # Get startup name and description
    startup_name = Utils.get_text_input("Enter your startup name")
    startup_description = Utils.get_text_input("Enter your startup description")

    # Return settings map
    %{
      cash_on_hand: cash_on_hand,
      provider: provider,
      name: startup_name,
      description: startup_description
    }
  end

  # Creates a new game state with the provided settings
  @spec start_new_game(%{
          cash_on_hand: Decimal.t(),
          provider: module(),
          name: String.t(),
          description: String.t()
        }) :: {Engine.GameState.t(), map()}
  defp start_new_game(settings) do
    # Create a new game state with the selected provider
    game_state = Engine.new_game(
      settings.name,
      settings.description,
      settings.provider
    )

    # Override the default cash on hand
    game_state = %{game_state | cash_on_hand: settings.cash_on_hand}

    # Get the initial situation
    situation = Engine.get_current_situation(game_state)

    {game_state, situation}
  end
end
