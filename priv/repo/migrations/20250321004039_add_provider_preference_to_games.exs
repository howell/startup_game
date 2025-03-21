defmodule StartupGame.Repo.Migrations.AddProviderPreferenceToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :provider_preference, :string
    end
  end
end
