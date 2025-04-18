defmodule StartupGame.Engine.GameState do
  @moduledoc """
  Pure in-memory representation of the game state.

  This module defines the core data structure that represents the state of a game,
  including the startup's information, financial state, ownership structure, and
  game progress.
  """

  alias StartupGame.Engine.{Scenario, ScenarioProvider}

  @type ownership_entry :: %{
          entity_name: String.t(),
          percentage: Decimal.t()
        }

  @type round_entry :: %{
          scenario_id: String.t(),
          situation: String.t(),
          player_input: String.t() | nil,
          outcome: String.t() | nil,
          cash_change: Decimal.t() | nil,
          burn_rate_change: Decimal.t() | nil,
          ownership_changes: [ownership_change()] | nil
        }

  @type ownership_change :: %{
          entity_name: String.t(),
          percentage_delta: Decimal.t()
        }

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          cash_on_hand: Decimal.t(),
          burn_rate: Decimal.t(),
          status: :in_progress | :completed | :failed,
          exit_type: :none | :acquisition | :ipo | :shutdown,
          exit_value: Decimal.t(),
          ownerships: [ownership_entry()],
          rounds: [round_entry()],
          current_scenario: String.t() | nil,
          current_scenario_data: Scenario.t() | nil,
          scenario_provider: ScenarioProvider.behaviour() | nil,
          error_message: String.t() | nil
        }
  defstruct name: nil,
            description: nil,
            cash_on_hand: Decimal.new("10000.00"),
            burn_rate: Decimal.new("1000.00"),
            status: :in_progress,
            exit_type: :none,
            exit_value: Decimal.new("0.00"),
            ownerships: [],
            rounds: [],
            current_scenario: nil,
            current_scenario_data: nil,
            scenario_provider: nil,
            error_message: nil

  @doc """
  Creates a new game state with the given name and description.

  ## Examples

      iex> GameState.new("TechNova", "AI-powered project management")
      %GameState{name: "TechNova", description: "AI-powered project management", ...}

  """
  @spec new(String.t(), String.t()) :: t()
  def new(name, description) do
    %__MODULE__{
      name: name,
      description: description,
      ownerships: [%{entity_name: "Founder", percentage: Decimal.new("100.00")}]
    }
  end

  @doc """
  Calculates the runway (months of cash left) based on current finances.

  ## Examples

      iex> game_state = %GameState{cash_on_hand: Decimal.new("10000.00"), burn_rate: Decimal.new("2000.00")}
      iex> GameState.calculate_runway(game_state)
      #Decimal<5.0>

  """
  @spec calculate_runway(t()) :: Decimal.t()
  def calculate_runway(%__MODULE__{} = state) do
    if Decimal.compare(state.burn_rate, Decimal.new("0")) == :gt do
      Decimal.div(state.cash_on_hand, state.burn_rate)
    else
      # Effectively infinite runway
      Decimal.new("999999999")
    end
  end
end
