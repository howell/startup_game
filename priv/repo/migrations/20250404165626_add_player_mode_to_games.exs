defmodule StartupGame.Repo.Migrations.AddPlayerModeToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :current_player_mode, :string, default: "responding", null: false
    end
  end
end
