defmodule StartupGame.Repo.Migrations.CreateOwnershipChanges do
  use Ecto.Migration

  def change do
    create table(:ownership_changes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entity_name, :string, null: false
      add :previous_percentage, :decimal, null: false
      add :new_percentage, :decimal, null: false
      add :change_type, :string, null: false
      add :game_id, references(:games, on_delete: :delete_all, type: :binary_id), null: false
      add :round_id, references(:rounds, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ownership_changes, [:game_id])
    create index(:ownership_changes, [:round_id])
    create index(:ownership_changes, [:entity_name, :game_id])
  end
end
