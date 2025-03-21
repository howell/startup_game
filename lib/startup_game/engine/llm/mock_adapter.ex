defmodule StartupGame.Engine.LLM.MockAdapter do
  @moduledoc """
  Mock LLM adapter for testing.

  This adapter returns predefined responses for testing purposes.
  """

  @behaviour StartupGame.Engine.LLM.Adapter

  @impl true
  def generate_completion(_system_prompt, _user_prompt, opts) do
    # Get the response type from options or default to "scenario"
    response_type = Map.get(opts, :response_type, "scenario")

    # Return a predefined response based on the type
    case response_type do
      "scenario" ->
        {:ok, generate_scenario_response()}

      "outcome" ->
        {:ok, generate_outcome_response()}

      "error" ->
        {:error, "Mock error response"}

      _ ->
        {:error, "Unknown response type: #{response_type}"}
    end
  end

  # Generate a mock scenario response
  defp generate_scenario_response do
    """
    {
      "id": "mock_scenario_123",
      "type": "funding",
      "situation": "Your startup has been approached by a venture capital firm interested in investing $2 million for a 15% stake. They're impressed with your product but concerned about your current burn rate. How do you respond to their offer?"
    }
    """
  end

  # Generate a mock outcome response
  defp generate_outcome_response do
    """
    {
      "text": "You successfully negotiate with the VC firm. After several meetings and due diligence, they agree to invest $2.5 million for a 12% stake, valuing your company at $20.8 million. This cash infusion will extend your runway by 18 months and allow you to hire key engineering talent.",
      "cash_change": 2500000,
      "burn_rate_change": 50000,
      "ownership_changes": [
        {
          "entity_name": "Founders",
          "previous_percentage": 80,
          "new_percentage": 70.4
        },
        {
          "entity_name": "Angel Investors",
          "previous_percentage": 20,
          "new_percentage": 17.6
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
  end
end
