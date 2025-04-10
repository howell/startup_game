defmodule StartupGame.Repo.Migrations.AddIsTrainingExampleToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :is_training_example, :boolean, default: false, null: false
    end

  end
end
