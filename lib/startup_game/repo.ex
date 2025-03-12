defmodule StartupGame.Repo do
  use Ecto.Repo,
    otp_app: :startup_game,
    adapter: Ecto.Adapters.Postgres
end
