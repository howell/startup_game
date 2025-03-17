defmodule StartupGame.Games.Ownership do
  @moduledoc """
  Schema representing ownership stakes in a startup.

  This tracks the current equity distribution in a company, including:
  - Who owns parts of the company (founders, investors, employees)
  - What percentage each entity owns
  """
  use StartupGame.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    entity_name: String.t(),
    percentage: Decimal.t(),
    game_id: Ecto.UUID.t(),
    game: StartupGame.Games.Game.t() | Ecto.Association.NotLoaded.t(),
    inserted_at: DateTime.t(),
    updated_at: DateTime.t()
  }

  schema "ownerships" do
    field :entity_name, :string
    field :percentage, :decimal

    belongs_to :game, StartupGame.Games.Game

    timestamps()
  end

  @doc false
  def changeset(ownership, attrs) do
    ownership
    |> cast(attrs, [:entity_name, :percentage, :game_id])
    |> validate_required([:entity_name, :percentage, :game_id])
    |> validate_number(:percentage, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  end
end
