defmodule StartupGame.Repo.Migrations.AddFounderReturnToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :founder_return, :decimal, default: 0
    end
  end
end
