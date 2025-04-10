defmodule StartupGame.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :startup_game

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def create_case_studies do
    load_app()
    Mix.Tasks.Game.CreateCaseStudies.run([])
  end

  def set_admin_role(email) do
    load_app()
    Mix.Tasks.Users.SetRole.set_user_role(email, "admin")
  end

  @doc """
  Updates the founder_return field for all completed games.

  This calculates the founder's return based on their ownership percentage
  and the game's exit value, then stores it in the founder_return field.

  This task should be run after the AddFounderReturnToGames migration.
  """
  def update_founder_returns do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn _repo ->
          alias StartupGame.Games.Game
          require Ecto.Query

          # Get all completed games
          games =
            Game
            |> Ecto.Query.where([g], g.status == :completed)
            |> Ecto.Query.where([g], g.exit_type in [:acquisition, :ipo])
            |> repo.all()
            |> repo.preload(:ownerships)

          # Update each game with calculated founder_return
          Enum.each(games, fn game ->
            try do
              # Find the founder's ownership
              founder_ownership =
                Enum.find(game.ownerships, fn ownership ->
                  ownership.entity_name == "Founder"
                end)

              # Calculate yield based on percentage
              founder_return =
                if founder_ownership do
                  percentage = Decimal.div(founder_ownership.percentage, Decimal.new(100))
                  Decimal.mult(game.exit_value, percentage)
                else
                  # Default if no founder record found
                  Decimal.mult(game.exit_value, Decimal.new("0.5"))
                end

              # Update the game with the calculated founder_return
              game
              |> Ecto.Changeset.change(%{founder_return: founder_return})
              |> repo.update!()
            rescue
              e ->
                IO.puts("Error updating game #{game.id}: #{inspect(e)}")
            end
          end)
        end)
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
