defmodule StartupGame.Engine.Scenario do
  @moduledoc """
  Defines the structure for game scenarios.

  A scenario represents a situation presented to the player. The choices
  and outcomes are managed by the scenario provider.
  """

  alias StartupGame.Engine.GameState

  # These types are kept for reference but are no longer part of the Scenario struct
  # They may be used by ScenarioProviders internally
  @type choice :: %{
          id: String.t(),
          text: String.t()
        }

  @type outcome :: %{
          text: String.t(),
          cash_change: Decimal.t(),
          burn_rate_change: Decimal.t(),
          ownership_changes: [GameState.ownership_change()] | nil,
          exit_type: :none | :acquisition | :ipo | :shutdown | nil,
          exit_value: Decimal.t() | nil
        }

  @type t :: %__MODULE__{
          id: String.t(),
          type: :funding | :acquisition | :hiring | :legal | :other,
          situation: String.t()
        }

  defstruct [:id, :type, :situation]
end
