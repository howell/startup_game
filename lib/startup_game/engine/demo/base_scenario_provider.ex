defmodule StartupGame.Engine.Demo.BaseScenarioProvider do
  @moduledoc """
  Base module providing common functionality for scenario providers.
  Contains shared utility functions used by both static and dynamic providers.
  """

  alias StartupGame.Engine.Scenario

  @doc """
  Matches a user's text response to a specific choice.

  Attempts to match by:
  1. Choice ID (e.g., "accept")
  2. Choice text (e.g., "Accept the offer")
  3. Letter option (e.g., "A" for the first choice)

  Returns {:ok, choice_id} if a match is found, otherwise {:error, reason}.
  """
  @spec match_response_to_choice(Scenario.t(), String.t(), [map()]) ::
          {:ok, String.t()} | {:error, String.t()}
  def match_response_to_choice(_scenario, response_text, choices) do
    # Normalize the response text
    normalized = String.trim(response_text) |> String.downcase()

    # Try to match to a choice by:
    # 1. Choice ID
    # 2. Choice text
    # 3. Letter (A, B, C) - assuming choices are presented in order
    choice_with_index = Enum.with_index(choices)

    match =
      Enum.find(choice_with_index, fn {choice, index} ->
        # A, B, C, etc.
        letter = <<65 + index::utf8>>

        String.contains?(normalized, String.downcase(choice.id)) ||
          String.contains?(normalized, String.downcase(choice.text)) ||
          String.contains?(normalized, String.downcase(letter))
      end)

    case match do
      {choice, _} ->
        {:ok, choice.id}

      nil ->
        {:error, "Could not determine your choice. Please try again with a clearer response."}
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
    choices_text = Enum.with_index(choices)
      |> Enum.map_join("\n", fn {choice, _index} ->
        "- #{choice.text} (`(#{String.first(choice.id |> String.upcase())})#{String.slice(choice.id, 1..-1//1)}`)"
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
