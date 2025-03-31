defmodule Mix.Tasks.Game.CreateCaseStudies do
  @moduledoc """
  Mix task to create or replace case studies in the database.

  ## Examples

      mix game.create_case_studies
  """
  use Mix.Task
  require Logger
  alias StartupGame.CaseStudies.{CaseStudy, Theranos}

  @shortdoc "Creates or replaces case studies"
  def run(_) do
    {:ok, _} = Application.ensure_all_started(:startup_game)

    Logger.info("Creating case studies...")

    # Create Theranos case study
    create_case_study(Theranos.case_study())

    Logger.info("Case studies created successfully")
  end

  defp create_case_study(case_study) do
    case CaseStudy.create_or_replace(case_study) do
      {:ok, game} ->
        Logger.info("Created case study: #{game.name}")
        {:ok, game}

      {:error, error} ->
        Logger.error("Failed to create case study: #{inspect(error)}")
        {:error, error}
    end
  end
end
