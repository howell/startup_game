defmodule StartupGame.Repo.Migrations.AllowRoundSituationNullable do
  use Ecto.Migration

  def change do
    alter table(:rounds) do
      modify :situation, :text, null: true
    end
  end
end
