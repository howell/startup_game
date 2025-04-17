defmodule StartupGame.Games.OwnershipChange do
  @moduledoc """
  Schema representing changes to ownership structure over time.

  This tracks the history of ownership changes, including:
  - Which entity's ownership changed
  - The percentage delta (change amount)
  - The type of change (initial, dilution, investment, transfer, exit)
  - Which round triggered the change

  Note: The old fields (previous_percentage and new_percentage) are maintained
  for backward compatibility but percentage_delta is the primary field used
  for calculations.
  """
  use StartupGame.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          entity_name: String.t(),
          # These fields are kept for backward compatibility
          old_previous_percentage: Decimal.t() | nil,
          old_new_percentage: Decimal.t() | nil,
          percentage_delta: Decimal.t(),
          change_type: :initial | :dilution | :investment | :transfer | :exit | :reacquisition,
          game_id: Ecto.UUID.t(),
          round_id: Ecto.UUID.t(),
          game: StartupGame.Games.Game.t() | Ecto.Association.NotLoaded.t(),
          round: StartupGame.Games.Round.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "ownership_changes" do
    field :entity_name, :string
    # Keep old fields for backward compatibility but use different names
    field :old_previous_percentage, :decimal
    field :old_new_percentage, :decimal
    # New delta-based field
    field :percentage_delta, :decimal

    field :change_type, Ecto.Enum,
      values: [:initial, :dilution, :investment, :transfer, :exit, :reacquisition]

    belongs_to :game, StartupGame.Games.Game
    belongs_to :round, StartupGame.Games.Round

    timestamps()
  end

  @doc """
  Changeset for creating a new ownership change with the delta-based approach.
  """
  def changeset(ownership_change, attrs) do
    ownership_change
    |> cast(attrs, [
      :entity_name,
      :percentage_delta,
      :change_type,
      :game_id,
      :round_id,
      :old_previous_percentage,
      :old_new_percentage
    ])
    |> validate_required([:entity_name, :percentage_delta, :change_type, :game_id, :round_id])
  end
end
