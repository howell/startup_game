defmodule StartupGame.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :string, null: false
      add :status, :string, default: "in_progress", null: false
      add :cash_on_hand, :decimal, null: false
      add :burn_rate, :decimal, null: false
      add :is_public, :boolean, default: false, null: false
      add :is_leaderboard_eligible, :boolean, default: false, null: false
      add :exit_value, :decimal, default: 0, null: false
      add :exit_type, :string, default: "none", null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:games, [:user_id])
    create index(:games, [:is_public, :is_leaderboard_eligible])
  end
end
