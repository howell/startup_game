defmodule StartupGame.Engine.LLM.MockAdapterTest do
  use ExUnit.Case, async: true

  alias StartupGame.Engine.LLM.MockAdapter

  describe "generate_completion/3" do
    test "returns a scenario response by default" do
      {:ok, response} = MockAdapter.generate_completion("system prompt", "user prompt", %{})
      assert is_binary(response)

      # Parse the response to verify it's valid JSON
      {:ok, parsed} = Jason.decode(response)
      assert Map.has_key?(parsed, "id")
      assert Map.has_key?(parsed, "type")
      assert Map.has_key?(parsed, "situation")
    end

    test "returns an outcome response when specified" do
      {:ok, response} = MockAdapter.generate_completion(
        "system prompt",
        "user prompt",
        %{response_type: "outcome"}
      )
      assert is_binary(response)

      # Parse the response to verify it's valid JSON
      {:ok, parsed} = Jason.decode(response)
      assert Map.has_key?(parsed, "text")
      assert Map.has_key?(parsed, "cash_change")
      assert Map.has_key?(parsed, "burn_rate_change")
      assert Map.has_key?(parsed, "ownership_changes")
      assert Map.has_key?(parsed, "exit_type")
    end

    test "returns an error when specified" do
      {:error, message} = MockAdapter.generate_completion(
        "system prompt",
        "user prompt",
        %{response_type: "error"}
      )
      assert message == "Mock error response"
    end

    test "returns an error for unknown response types" do
      {:error, message} = MockAdapter.generate_completion(
        "system prompt",
        "user prompt",
        %{response_type: "unknown"}
      )
      assert String.starts_with?(message, "Unknown response type:")
    end
  end
end
