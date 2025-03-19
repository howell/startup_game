defmodule StartupGame.Games.Round do
  @moduledoc """
  Schema representing a round of gameplay in the startup simulation.

  A round represents a single interaction in the game, including:
  - The situation presented to the player
  - The player's response
  - The outcome of the decision
  - Financial impacts (cash and burn rate changes)
  """
  use StartupGame.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          situation: String.t(),
          response: String.t() | nil,
          outcome: String.t() | nil,
          cash_change: Decimal.t(),
          burn_rate_change: Decimal.t(),
          game_id: Ecto.UUID.t(),
          game: StartupGame.Games.Game.t() | Ecto.Association.NotLoaded.t(),
          ownership_changes:
            [StartupGame.Games.OwnershipChange.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "rounds" do
    field :situation, :string
    field :response, :string
    field :outcome, :string
    field :cash_change, :decimal, default: 0
    field :burn_rate_change, :decimal, default: 0

    belongs_to :game, StartupGame.Games.Game
    has_many :ownership_changes, StartupGame.Games.OwnershipChange

    timestamps()
  end

  @doc false
  def changeset(round, attrs) do
    round
    |> cast(attrs, [:situation, :response, :outcome, :cash_change, :burn_rate_change, :game_id])
    |> validate_required([:situation, :game_id])
  end
end
