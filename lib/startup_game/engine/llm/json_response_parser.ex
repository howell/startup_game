defmodule StartupGame.Engine.LLM.JSONResponseParser do
  @moduledoc """
  Parser for JSON responses from LLMs.

  This module implements the ResponseParser behavior and handles parsing
  JSON responses into the expected scenario and outcome formats.

  It can handle JSON with surrounding text, extracting the JSON object
  from the content before parsing.
  """

  @behaviour StartupGame.Engine.LLM.ResponseParser

  alias StartupGame.Engine.Scenario
  alias StartupGame.Engine.LLM.BaseScenarioProvider

  @impl true
  def parse_scenario(content) do
    # Check if this is a two-part response
    if String.contains?(content, "---JSON DATA---") do
      # Split at delimiter to get narrative and JSON parts
      [narrative_part, json_part] = String.split(content, "---JSON DATA---", parts: 2)

      # Extract and parse the JSON part
      case extract_json(json_part) |> Jason.decode() do
        {:ok, scenario_data} ->
          # Use the narrative part as the situation
          scenario = %Scenario{
            id: Map.get(scenario_data, "id", "llm_scenario_#{:rand.uniform(1000)}"),
            type: BaseScenarioProvider.parse_scenario_type(Map.get(scenario_data, "type", "other")),
            situation: String.trim(narrative_part)
          }

          {:ok, scenario}

        {:error, err} ->
          {:error, "Failed to parse LLM response as JSON: #{Exception.message(err)}"}
      end
    else
      # Handle traditional format (no delimiter)
      case extract_json(content) |> Jason.decode() do
        {:ok, scenario_data} ->
          scenario = %Scenario{
            id: Map.get(scenario_data, "id", "llm_scenario_#{:rand.uniform(1000)}"),
            type: BaseScenarioProvider.parse_scenario_type(Map.get(scenario_data, "type", "other")),
            situation: Map.get(scenario_data, "situation", "")
          }

          {:ok, scenario}

        {:error, err} ->
          {:error, "Failed to parse LLM response as JSON: #{Exception.message(err)}"}
      end
    end
  end

  @impl true
  def parse_outcome(content) do
    # Check if this is a two-part response
    if String.contains?(content, "---JSON DATA---") do
      # Split at delimiter to get narrative and JSON parts
      [narrative_part, json_part] = String.split(content, "---JSON DATA---", parts: 2)

      # Extract and parse the JSON part
      case extract_json(json_part) |> Jason.decode() do
        {:ok, outcome_data} ->
          # Use the narrative part as the text
          outcome = %{
            text: String.trim(narrative_part),
            cash_change:
              BaseScenarioProvider.parse_decimal(Map.get(outcome_data, "cash_change", 0)),
            burn_rate_change:
              BaseScenarioProvider.parse_decimal(Map.get(outcome_data, "burn_rate_change", 0)),
            ownership_changes:
              BaseScenarioProvider.parse_ownership_changes(
                Map.get(outcome_data, "ownership_changes")
              ),
            exit_type:
              BaseScenarioProvider.parse_exit_type(Map.get(outcome_data, "exit_type", "none")),
            exit_value:
              BaseScenarioProvider.parse_exit_value(
                Map.get(outcome_data, "exit_value"),
                Map.get(outcome_data, "exit_type", "none")
              )
          }

          {:ok, outcome}

        {:error, err} ->
          {:error, "Failed to parse LLM response as JSON: #{Exception.message(err)}"}
      end
    else
      # Handle traditional format (no delimiter)
      case extract_json(content) |> Jason.decode() do
        {:ok, outcome_data} ->
          # Convert the outcome data to the expected format
          outcome = %{
            text: Map.get(outcome_data, "text", ""),
            cash_change:
              BaseScenarioProvider.parse_decimal(Map.get(outcome_data, "cash_change", 0)),
            burn_rate_change:
              BaseScenarioProvider.parse_decimal(Map.get(outcome_data, "burn_rate_change", 0)),
            ownership_changes:
              BaseScenarioProvider.parse_ownership_changes(
                Map.get(outcome_data, "ownership_changes")
              ),
            exit_type:
              BaseScenarioProvider.parse_exit_type(Map.get(outcome_data, "exit_type", "none")),
            exit_value:
              BaseScenarioProvider.parse_exit_value(
                Map.get(outcome_data, "exit_value"),
                Map.get(outcome_data, "exit_type", "none")
              )
          }

          {:ok, outcome}

        {:error, err} ->
          {:error, "Failed to parse LLM response as JSON: #{Exception.message(err)}"}
      end
    end
  end


  # Private helper function to extract JSON from content with surrounding text
  defp extract_json(content) do
    if String.contains?(content, "{") and String.contains?(content, "}") do
      # match content before the first { and after the last }
      r = ~r/(^[^{]*)|([^}]*$)/
      String.replace(content, r, "")
    else
      content
    end
  end
end
