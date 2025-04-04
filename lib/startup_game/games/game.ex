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
          status: status(),
          cash_on_hand: Decimal.t(),
          burn_rate: Decimal.t(),
          is_public: boolean(),
          is_leaderboard_eligible: boolean(),
          is_case_study: boolean(),
          exit_value: Decimal.t(),
          exit_type: exit_type(),
          founder_return: Decimal.t(),
          provider_preference: String.t() | nil,
          current_player_mode: player_mode(),
          user_id: Ecto.UUID.t(),
          user: StartupGame.Accounts.User.t() | Ecto.Association.NotLoaded.t(),
          rounds: [StartupGame.Games.Round.t()] | Ecto.Association.NotLoaded.t(),
          ownerships: [StartupGame.Games.Ownership.t()] | Ecto.Association.NotLoaded.t(),
          ownership_changes:
            [StartupGame.Games.OwnershipChange.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @type status :: :in_progress | :completed | :failed
  @type exit_type :: :none | :acquisition | :ipo | :shutdown
  @type player_mode() :: :responding | :acting

  schema "games" do
    field :name, :string
    field :description, :string
    field :status, Ecto.Enum, values: [:in_progress, :completed, :failed], default: :in_progress
    field :cash_on_hand, :decimal
    field :burn_rate, :decimal
    field :is_public, :boolean, default: false
    field :is_leaderboard_eligible, :boolean, default: false
    field :is_case_study, :boolean, default: false
    field :exit_value, :decimal, default: 0
    field :exit_type, Ecto.Enum, values: [:none, :acquisition, :ipo, :shutdown], default: :none
    field :founder_return, :decimal, default: 0
    field :provider_preference, :string
    field :current_player_mode, Ecto.Enum, values: [:responding, :acting], default: :responding

    belongs_to :user, StartupGame.Accounts.User
    has_many :rounds, StartupGame.Games.Round, on_delete: :delete_all
    has_many :ownerships, StartupGame.Games.Ownership, on_delete: :delete_all
    has_many :ownership_changes, StartupGame.Games.OwnershipChange, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [
      :name,
      :description,
      :status,
      :cash_on_hand,
      :burn_rate,
      :is_public,
      :is_leaderboard_eligible,
      :is_case_study,
      :exit_value,
      :exit_type,
      :founder_return,
      :user_id,
      :provider_preference,
      :current_player_mode
    ])
    |> validate_required([:name, :description, :cash_on_hand, :burn_rate, :user_id])
  end
end
