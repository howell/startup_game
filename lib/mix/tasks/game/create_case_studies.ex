defmodule Mix.Tasks.Game.CreateCaseStudies do
  @moduledoc """
  Mix task to create or replace case studies in the database.

  ## Examples

      mix game.create_case_studies
  """
  use Mix.Task
  require Logger
  alias StartupGame.CaseStudies.{CaseStudy, Theranos, WeWork, FTX}

  @case_studies [Theranos.case_study(), WeWork.case_study(), FTX.case_study()]

  @shortdoc "Creates or replaces case studies"
  def run(_) do
    {:ok, _} = Application.ensure_all_started(:startup_game)

    Logger.info("Creating case studies...")

    # Create Theranos case study
    for case_study <- @case_studies do
      create_case_study(case_study)
    end

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
