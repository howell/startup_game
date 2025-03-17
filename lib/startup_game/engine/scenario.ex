defmodule StartupGame.Engine.Scenario do
  @moduledoc """
  Defines the structure for game scenarios and their possible outcomes.

  A scenario represents a situation presented to the player, the choices
  they can make, and the outcomes of those choices.
  """

  alias StartupGame.Engine.GameState

  @type choice :: %{
    id: String.t(),
    text: String.t()
  }

  @type outcome :: %{
    choice_id: String.t(),
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
    situation: String.t(),
    choices: [choice()],
    outcomes: %{required(String.t()) => outcome()}
  }

  defstruct [:id, :type, :situation, :choices, :outcomes]
end
