defmodule StartupGame.Engine.LLM.AnthropicAdapter do
  @moduledoc """
  LLM adapter for Anthropic's Claude models.

  This adapter uses LangChain to interact with Claude models.
  """

  @behaviour StartupGame.Engine.LLM.Adapter

  alias LangChain.ChatModels.ChatAnthropic
  alias LangChain.Message
  alias LangChain.Chains.LLMChain

  require Logger

  @impl true
  def generate_completion(system_prompt, user_prompt, opts) do
    # Get the model name from options or use a default
    model = Map.get(opts, :model, "claude-3-opus-20240229")

    # Create a new ChatAnthropic model instance
    anthropic =
      ChatAnthropic.new!(%{
        model: model,
        stream: false
      })

    # Create an LLMChain with the model
    try do
      {:ok, chain} =
        %{llm: anthropic}
        |> LLMChain.new!()
        |> LLMChain.add_messages([
          Message.new_system!(system_prompt),
          Message.new_user!(user_prompt)
        ])
        |> LLMChain.run()

      Logger.debug("LLM Response:\n#{chain.last_message.content}")
      # Return just the content
      {:ok, chain.last_message.content}
    rescue
      e -> {:error, "LLM API error: #{inspect(e)}"}
    end
  end
end
