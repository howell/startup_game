defmodule StartupGame.Repo.Migrations.CreateRounds do
  use Ecto.Migration

  def change do
    create table(:rounds, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :situation, :text, null: false
      add :response, :text
      add :outcome, :text
      add :cash_change, :decimal, default: 0, null: false
      add :burn_rate_change, :decimal, default: 0, null: false
      add :game_id, references(:games, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:rounds, [:game_id])
  end
end
