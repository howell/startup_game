defmodule StartupGame.Repo.Migrations.CreateOwnerships do
  use Ecto.Migration

  def change do
    create table(:ownerships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entity_name, :string, null: false
      add :percentage, :decimal, null: false
      add :game_id, references(:games, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ownerships, [:game_id])
    create index(:ownerships, [:entity_name, :game_id])
  end
end
