defmodule StartupGame.Engine.Demo.BaseScenarioProvider do
  @moduledoc """
  Base module providing common functionality for scenario providers.
  Contains shared utility functions used by both static and dynamic providers.
  """

  defmacro __using__(_) do
    mod = __MODULE__

    quote do
      @behaviour StartupGame.Engine.ScenarioProvider

      alias unquote(mod)

      @impl StartupGame.Engine.ScenarioProvider
      def get_next_scenario_async(game_state, game_id, current_scenario_id) do
        StartupGame.Engine.Demo.BaseScenarioProvider.default_get_next_scenario_async(
          __MODULE__,
          game_state,
          game_id,
          current_scenario_id
        )
      end

      @impl StartupGame.Engine.ScenarioProvider
      def generate_outcome_async(game_state, game_id, scenario, response_text) do
        StartupGame.Engine.Demo.BaseScenarioProvider.default_generate_outcome_async(
          __MODULE__,
          game_state,
          game_id,
          scenario,
          response_text
        )
      end
    end
  end

  alias StartupGame.Engine.Scenario
  alias StartupGame.StreamingService

  @doc """
  Matches a user's text response to a specific choice.

  Attempts to match by:
  1. Explicit selection keys (if provided)
  2. First letter of the choice (e.g., "A" for the first choice)

  Returns {:ok, choice_id} if a match is found, otherwise {:error, reason}.
  """
  @spec match_response_to_choice(Scenario.t(), String.t(), [map()]) ::
          {:ok, String.t()} | {:error, String.t()}
  def match_response_to_choice(_scenario, response_text, choices) do
    # Normalize the response text
    normalized = String.trim(response_text) |> String.downcase()

    # Try to match to a choice by:
    # 1. Selection keys (if provided in the choice)

    match =
      Enum.find(choices, fn choice ->
        # Get the selection keys (if provided) or use fallbacks
        selection_keys = Map.get(choice, :selection_keys, [])

        # Check if any of the selection keys match the normalized response
        Enum.any?(selection_keys, fn key ->
          String.contains?(normalized, key)
        end)
      end)

    case match do
      nil ->
        {:error, "Could not determine your choice. Please try again with a clearer response."}

      choice ->
        {:ok, choice.id}
    end
  end

  @doc """
  Formats a list of choices into a human-readable string for display in a scenario.

  ## Parameters
    - choices: List of choice maps, each with :id and :text fields

  ## Returns
    A formatted string showing all choices
  """
  @spec format_choices_for_display([map()]) :: String.t()
  def format_choices_for_display(choices) do
    choices_text =
      Enum.map_join(choices, "\n", fn choice ->
        # Get selection keys with empty list as default
        selection_keys = choice.selection_keys

        # Format the keys for display (e.g., "a", "accept")
        keys_display =
          Enum.map_join(selection_keys, ", ", fn key ->
            "\"#{key}\""
          end)

        "- #{choice.text} (Enter #{keys_display})"
      end)

    "\n\nDo you:\n#{choices_text}"
  end

  @doc """
  Adds formatted choices to a scenario's situation text.

  ## Parameters
    - scenario: The scenario to update
    - choices: List of choice maps

  ## Returns
    Updated scenario with choices appended to situation text
  """
  @spec add_choices_to_scenario(Scenario.t(), [map()]) :: Scenario.t()
  def add_choices_to_scenario(scenario, choices) do
    choices_text = format_choices_for_display(choices)
    %{scenario | situation: scenario.situation <> choices_text}
  end

  @doc """
  Default implementation of get_next_scenario_async.
  """
  def default_get_next_scenario_async(mod, game_state, game_id, current_scenario_id) do
    stream_id = UUID.uuid4()

    Task.async(fn ->
      result = mod.get_next_scenario(game_state, current_scenario_id)

      StreamingService.broadcast_complete(
        game_id,
        stream_id,
        {:ok, result}
      )
    end)

    {:ok, stream_id}
  end

  @doc """
  Default implementation of generate_outcome_async.
  """
  def default_generate_outcome_async(mod, game_state, game_id, scenario, response_text) do
    stream_id = UUID.uuid4()

    Task.async(fn ->
      result = mod.generate_outcome(game_state, scenario, response_text)

      StreamingService.broadcast_complete(
        game_id,
        stream_id,
        result
      )
    end)

    {:ok, stream_id}
  end
end
