defmodule StartupGame.Games.OwnershipChange do
  @moduledoc """
  Schema representing changes to ownership structure over time.

  This tracks the history of ownership changes, including:
  - Which entity's ownership changed
  - Previous and new ownership percentages
  - The type of change (initial, dilution, investment, transfer, exit)
  - Which round triggered the change
  """
  use StartupGame.Schema
  import Ecto.Changeset

  schema "ownership_changes" do
    field :entity_name, :string
    field :previous_percentage, :decimal
    field :new_percentage, :decimal
    field :change_type, Ecto.Enum, values: [:initial, :dilution, :investment, :transfer, :exit]

    belongs_to :game, StartupGame.Games.Game
    belongs_to :round, StartupGame.Games.Round

    timestamps()
  end

  @doc false
  def changeset(ownership_change, attrs) do
    ownership_change
    |> cast(attrs, [:entity_name, :previous_percentage, :new_percentage, :change_type, :game_id, :round_id])
    |> validate_required([:entity_name, :previous_percentage, :new_percentage, :change_type, :game_id, :round_id])
    |> validate_number(:previous_percentage, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_number(:new_percentage, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  end
end
