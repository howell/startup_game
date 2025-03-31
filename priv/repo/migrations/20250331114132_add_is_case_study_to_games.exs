defmodule StartupGame.Repo.Migrations.AddIsCaseStudyToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :is_case_study, :boolean, default: false, null: false
    end
  end
end
