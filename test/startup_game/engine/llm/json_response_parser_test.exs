defmodule StartupGame.Engine.LLM.JSONResponseParserTest do
  use ExUnit.Case, async: true

  alias StartupGame.Engine.LLM.JSONResponseParser
  alias StartupGame.Engine.Scenario

  describe "parse_scenario/1" do
    test "parses scenario from two-part response format" do
      json = """
      This is a narrative description of a funding scenario that would be shown to the user.
      A venture capital firm is interested in your startup. What will you do?
      ---JSON DATA---
      {
        "id": "test_scenario_123",
        "type": "funding"
      }
      """

      assert {:ok, scenario} = JSONResponseParser.parse_scenario(json)
      assert %Scenario{} = scenario
      assert scenario.id == "test_scenario_123"
      assert scenario.type == :funding

      assert scenario.situation ==
               "This is a narrative description of a funding scenario that would be shown to the user.\nA venture capital firm is interested in your startup. What will you do?"
    end

    test "successfully parses valid scenario JSON" do
      json = """
      {
        "id": "test_scenario_123",
        "type": "funding",
        "situation": "Your startup has been approached by a venture capital firm."
      }
      """

      assert {:ok, scenario} = JSONResponseParser.parse_scenario(json)
      assert %Scenario{} = scenario
      assert scenario.id == "test_scenario_123"
      assert scenario.type == :funding
      assert scenario.situation == "Your startup has been approached by a venture capital firm."
    end

    test "generates a random ID if none provided" do
      json = """
      {
        "type": "hiring",
        "situation": "You need to hire a new CTO."
      }
      """

      assert {:ok, scenario} = JSONResponseParser.parse_scenario(json)
      assert %Scenario{} = scenario
      assert is_binary(scenario.id)
      assert String.starts_with?(scenario.id, "llm_scenario_")
    end

    test "defaults to 'other' type if none provided" do
      json = """
      {
        "id": "test_scenario_456",
        "situation": "Something unexpected happened."
      }
      """

      assert {:ok, scenario} = JSONResponseParser.parse_scenario(json)
      assert scenario.type == :other
    end

    test "returns error for invalid JSON" do
      json = "{ invalid json }"
      assert {:error, error_message} = JSONResponseParser.parse_scenario(json)
      assert String.contains?(error_message, "Failed to parse LLM response as JSON")
    end

    test "handles JSON with preceding text" do
      json = """
      Here's the situation you asked for:
      {
        "id": "test_scenario_123",
        "type": "funding",
        "situation": "Your startup has been approached by a venture capital firm."
      }
      """

      assert {:ok, scenario} = JSONResponseParser.parse_scenario(json)
      assert %Scenario{} = scenario
      assert scenario.id == "test_scenario_123"
      assert scenario.type == :funding
      assert scenario.situation == "Your startup has been approached by a venture capital firm."
    end

    test "handles JSON with trailing text" do
      json = """
      {
        "id": "test_scenario_456",
        "type": "hiring",
        "situation": "You need to hire a new CTO."
      }
      I hope this scenario works for your game!
      """

      assert {:ok, scenario} = JSONResponseParser.parse_scenario(json)
      assert %Scenario{} = scenario
      assert scenario.id == "test_scenario_456"
      assert scenario.type == :hiring
      assert scenario.situation == "You need to hire a new CTO."
    end

    test "handles JSON with both preceding and trailing text" do
      json = """
      Let me create a scenario for you:
      {
        "id": "test_scenario_789",
        "type": "other",
        "situation": "You need to decide on a new product feature."
      }
      Let me know if you need any clarification!
      """

      assert {:ok, scenario} = JSONResponseParser.parse_scenario(json)
      assert %Scenario{} = scenario
      assert scenario.id == "test_scenario_789"
      assert scenario.type == :other
      assert scenario.situation == "You need to decide on a new product feature."
    end
  end

  describe "parse_outcome/1" do
    test "parses outcome from two-part response format" do
      json = """
      You successfully negotiated with the VC firm. They've agreed to invest $2.5 million in your startup,
      but they want a 12% stake in the company. This will dilute the founders' ownership from 80% to 70.4%.
      The investment will increase your monthly burn rate by $50,000 as you'll need to hire more staff.
      ---JSON DATA---
      {
        "cash_change": 2500000,
        "burn_rate_change": 50000,
        "ownership_changes": [
          {
            "entity_name": "Founders",
            "previous_percentage": 80,
            "new_percentage": 70.4
          },
          {
            "entity_name": "VC Firm",
            "previous_percentage": 0,
            "new_percentage": 12
          }
        ],
        "exit_type": "none"
      }
      """

      assert {:ok, outcome} = JSONResponseParser.parse_outcome(json)
      assert outcome.text =~ "You successfully negotiated with the VC firm."
      assert Decimal.equal?(outcome.cash_change, Decimal.new("2500000"))
      assert Decimal.equal?(outcome.burn_rate_change, Decimal.new("50000"))
      assert length(outcome.ownership_changes) == 2
      assert outcome.exit_type == :none
      assert outcome.exit_value == nil
    end

    test "successfully parses valid outcome JSON" do
      json = """
      {
        "text": "You successfully negotiate with the VC firm.",
        "cash_change": 2500000,
        "burn_rate_change": 50000,
        "ownership_changes": [
          {
            "entity_name": "Founders",
            "previous_percentage": 80,
            "new_percentage": 70.4
          },
          {
            "entity_name": "VC Firm",
            "previous_percentage": 0,
            "new_percentage": 12
          }
        ],
        "exit_type": "none"
      }
      """

      assert {:ok, outcome} = JSONResponseParser.parse_outcome(json)
      assert outcome.text == "You successfully negotiate with the VC firm."
      assert Decimal.equal?(outcome.cash_change, Decimal.new("2500000"))
      assert Decimal.equal?(outcome.burn_rate_change, Decimal.new("50000"))
      assert length(outcome.ownership_changes) == 2
      assert outcome.exit_type == :none
      assert outcome.exit_value == nil
    end

    test "handles ownership_changes: null" do
      json = """
      {
        "text": "You make a decision with no ownership changes.",
        "cash_change": 10000,
        "burn_rate_change": 0,
        "ownership_changes": null,
        "exit_type": "none"
      }
      """

      assert {:ok, outcome} = JSONResponseParser.parse_outcome(json)
      assert outcome.ownership_changes == nil
    end

    test "handles exit events" do
      json = """
      {
        "text": "Your startup gets acquired!",
        "cash_change": 0,
        "burn_rate_change": 0,
        "ownership_changes": null,
        "exit_type": "acquisition",
        "exit_value": 10000000
      }
      """

      assert {:ok, outcome} = JSONResponseParser.parse_outcome(json)
      assert outcome.exit_type == :acquisition
      assert Decimal.equal?(outcome.exit_value, Decimal.new("10000000"))
    end

    test "returns error for invalid JSON" do
      json = "{ invalid json }"
      assert {:error, error_message} = JSONResponseParser.parse_outcome(json)
      assert String.contains?(error_message, "Failed to parse LLM response as JSON")
    end

    test "handles outcome JSON with surrounding text" do
      json = """
      Here's the outcome of your decision:
      {
        "text": "You successfully negotiate with the VC firm.",
        "cash_change": 2500000,
        "burn_rate_change": 50000,
        "ownership_changes": [
          {
            "entity_name": "Founders",
            "percentage_delta": -9.6
          },
          {
            "entity_name": "VC Firm",
            "percentage_delta": 9.6
          }
        ],
        "exit_type": "none"
      }
      I hope this outcome makes sense for your game!
      """

      assert {:ok, outcome} = JSONResponseParser.parse_outcome(json)
      assert outcome.text == "You successfully negotiate with the VC firm."
      assert Decimal.equal?(outcome.cash_change, Decimal.new("2500000"))
      assert Decimal.equal?(outcome.burn_rate_change, Decimal.new("50000"))
      assert length(outcome.ownership_changes) == 2

      # Test with specific entity lookups rather than relying on order
      founders_change =
        Enum.find(outcome.ownership_changes, fn c -> c.entity_name == "Founders" end)

      vc_change = Enum.find(outcome.ownership_changes, fn c -> c.entity_name == "VC Firm" end)

      assert Decimal.equal?(founders_change.percentage_delta, Decimal.new("-9.6"))
      assert Decimal.equal?(vc_change.percentage_delta, Decimal.new("9.6"))
      assert outcome.exit_type == :none
    end
  end
end
