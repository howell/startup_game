defmodule StartupGame.Repo.Migrations.AddSystemPromptsToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :scenario_system_prompt, :text, null: true
      add :outcome_system_prompt, :text, null: true
    end

  end
end
