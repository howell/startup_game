defmodule Mix.Tasks.Game.Cli do
  @moduledoc """
  Runs the startup game in a command-line interface.

  ## Examples

      mix game.cli

  """
  use Mix.Task

  @shortdoc "Run the startup game CLI"
  @impl Mix.Task
  @spec run(list()) :: :ok
  def run(_) do
    # Ensure all dependencies are started
    Mix.Task.run("app.config")
    Application.ensure_all_started(:startup_game)
    StartupGame.CLI.Main.start()
  end
end
