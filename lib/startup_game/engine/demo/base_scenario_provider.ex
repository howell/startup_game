defmodule StartupGame.Engine.Demo.BaseScenarioProvider do
  @moduledoc """
  Base module providing common functionality for scenario providers.
  Contains shared utility functions used by both static and dynamic providers.
  """

  alias StartupGame.Engine.Scenario

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
end
