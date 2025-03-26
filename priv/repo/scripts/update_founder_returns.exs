# Script to update founder_return field for all existing games
# Run with: mix run priv/repo/scripts/update_founder_returns.exs

alias StartupGame.Repo
alias StartupGame.Games.Game

# Get all completed games
games =
  Game
  |> Ecto.Query.where([g], g.status == :completed)
  |> Ecto.Query.where([g], g.exit_type in [:acquisition, :ipo])
  |> Repo.all()
  |> Repo.preload(:ownerships)

# Update each game with calculated founder_return
for game <- games do
  # Find the founder's ownership
  founder_ownership =
    Enum.find(game.ownerships, fn ownership ->
      ownership.entity_name == "Founder"
    end)

  # Calculate yield based on percentage
  founder_return = if founder_ownership do
    percentage = Decimal.div(founder_ownership.percentage, Decimal.new(100))
    Decimal.mult(game.exit_value, percentage)
  else
    # Default if no founder record found
    Decimal.mult(game.exit_value, Decimal.new("0.5"))
  end

  # Update the game with the calculated founder_return
  game
  |> Ecto.Changeset.change(%{founder_return: founder_return})
  |> Repo.update!()
end

IO.puts("Updated founder_return for #{length(games)} games")
