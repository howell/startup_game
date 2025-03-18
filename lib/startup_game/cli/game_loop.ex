defmodule StartupGame.CLI.GameLoop do
  @moduledoc """
  Manages the main game loop for the CLI version of the startup game.

  This module is responsible for running the game loop, displaying the current
  scenario, getting user responses, and processing those responses until the game
  is completed.
  """

  alias StartupGame.CLI.Utils
  alias StartupGame.Engine.GameRunner

  @doc """
  Runs the main game loop until the game is completed.

  ## Parameters

  - game_state: The initial game state
  - initial_situation: The initial situation to present to the user

  ## Returns

  The final game state after the game is completed
  """
  @spec run(StartupGame.Engine.GameState.t(), map()) :: StartupGame.Engine.GameState.t()
  def run(game_state, initial_situation) do
    # Display initial game state
    Utils.display_game_state(game_state)

    # Start with the initial situation
    situation = initial_situation

    # Run the game loop
    game_loop(game_state, situation)
  end

  # Core game loop that processes scenarios and responses
  @spec game_loop(StartupGame.Engine.GameState.t(), map()) :: StartupGame.Engine.GameState.t()
  defp game_loop(game_state, situation) do
    # Display the current situation
    Utils.display_situation(situation)

    # Get user response
    response = Utils.get_response(game_state.current_scenario_data)

    # Process the response
    {updated_state, next_situation} = GameRunner.make_response(game_state, response)

    # Display the outcome of the last round
    Utils.display_outcome(updated_state)

    # Check if the game is over
    case next_situation do
      nil ->
        # Game is over
        updated_state

      _ ->
        # Continue to the next round
        Utils.display_game_state(updated_state)
        game_loop(updated_state, next_situation)
    end
  end
end
