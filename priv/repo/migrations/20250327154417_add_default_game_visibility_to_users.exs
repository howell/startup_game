defmodule StartupGame.Repo.Migrations.AddDefaultGameVisibilityToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :default_game_visibility, :string, default: "private", null: false
    end
  end
end
