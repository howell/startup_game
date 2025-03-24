defmodule StartupGame.Engine.LLM.PromptExamplesTest do
  use ExUnit.Case, async: true
  alias StartupGame.Engine.LLM.PromptExamples

  describe "scenario_examples/0" do
    test "returns a list of scenario examples" do
      examples = PromptExamples.scenario_examples()

      assert is_list(examples)
      assert length(examples) > 0

      # Check structure of first example
      example = List.first(examples)
      assert Map.has_key?(example, :description)
      assert Map.has_key?(example, :narrative)
      assert Map.has_key?(example, :json)

      # Check JSON structure
      json = example.json
      assert Map.has_key?(json, "id")
      assert Map.has_key?(json, "type")
    end
  end

  describe "outcome_examples/0" do
    test "returns a list of outcome examples" do
      examples = PromptExamples.outcome_examples()

      assert is_list(examples)
      assert length(examples) > 0

      # Check structure of first example
      example = List.first(examples)
      assert Map.has_key?(example, :description)
      assert Map.has_key?(example, :narrative)
      assert Map.has_key?(example, :json)

      # Check JSON structure
      json = example.json
      assert Map.has_key?(json, "cash_change")
      assert Map.has_key?(json, "burn_rate_change")
      assert Map.has_key?(json, "exit_type")
    end
  end

  describe "format_scenario_examples/0" do
    test "formats scenario examples with XML tags" do
      formatted = PromptExamples.format_scenario_examples()

      assert is_binary(formatted)
      assert String.contains?(formatted, "<example>")
      assert String.contains?(formatted, "</example>")
      assert String.contains?(formatted, "---JSON DATA---")

      # Verify JSON is included
      assert String.contains?(formatted, "\"id\":")
      assert String.contains?(formatted, "\"type\":")
    end
  end

  describe "format_outcome_examples/0" do
    test "formats outcome examples with XML tags" do
      formatted = PromptExamples.format_outcome_examples()

      assert is_binary(formatted)
      assert String.contains?(formatted, "<example>")
      assert String.contains?(formatted, "</example>")
      assert String.contains?(formatted, "---JSON DATA---")

      # Verify JSON is included
      assert String.contains?(formatted, "\"cash_change\":")
      assert String.contains?(formatted, "\"burn_rate_change\":")
      assert String.contains?(formatted, "\"exit_type\":")
    end
  end
end
