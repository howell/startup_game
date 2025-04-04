defmodule StartupGame.Repo.Migrations.RenameRoundResponseToPlayerInput do
  use Ecto.Migration

  def change do
    rename table(:rounds), :response, to: :player_input
  end
end
