defmodule StartupGame.Games.Game do
  @moduledoc """
  Schema representing a game in the startup simulation.

  A game tracks the state of a startup company, including:
  - Basic information (name, description)
  - Financial state (cash, burn rate)
  - Ownership structure (via associations)
  - Game progress and outcome
  """
  use StartupGame.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t(),
    description: String.t(),
    status: :in_progress | :completed | :failed,
    cash_on_hand: Decimal.t(),
    burn_rate: Decimal.t(),
    is_public: boolean(),
    is_leaderboard_eligible: boolean(),
    exit_value: Decimal.t(),
    exit_type: :none | :acquisition | :ipo | :shutdown,
    user_id: Ecto.UUID.t(),
    user: StartupGame.Accounts.User.t() | Ecto.Association.NotLoaded.t(),
    rounds: [StartupGame.Games.Round.t()] | Ecto.Association.NotLoaded.t(),
    ownerships: [StartupGame.Games.Ownership.t()] | Ecto.Association.NotLoaded.t(),
    ownership_changes: [StartupGame.Games.OwnershipChange.t()] | Ecto.Association.NotLoaded.t(),
    inserted_at: DateTime.t(),
    updated_at: DateTime.t()
  }

  schema "games" do
    field :name, :string
    field :description, :string
    field :status, Ecto.Enum, values: [:in_progress, :completed, :failed], default: :in_progress
    field :cash_on_hand, :decimal
    field :burn_rate, :decimal
    field :is_public, :boolean, default: false
    field :is_leaderboard_eligible, :boolean, default: false
    field :exit_value, :decimal, default: 0
    field :exit_type, Ecto.Enum, values: [:none, :acquisition, :ipo, :shutdown], default: :none

    belongs_to :user, StartupGame.Accounts.User
    has_many :rounds, StartupGame.Games.Round
    has_many :ownerships, StartupGame.Games.Ownership
    has_many :ownership_changes, StartupGame.Games.OwnershipChange

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name, :description, :status, :cash_on_hand, :burn_rate, :is_public, :is_leaderboard_eligible, :exit_value, :exit_type, :user_id])
    |> validate_required([:name, :description, :cash_on_hand, :burn_rate, :user_id])
  end
end
