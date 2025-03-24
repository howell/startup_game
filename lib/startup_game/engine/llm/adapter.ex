defmodule StartupGame.Engine.LLM.Adapter do
  @moduledoc """
  Behaviour for LLM adapters that can be used with BaseLLMScenarioProvider.

  This defines the interface that all LLM adapters must implement to be
  compatible with the LLM scenario provider system.
  """

  @type behaviour() :: module()

  @doc """
  Generates a completion from the LLM based on the provided system and user prompts.

  ## Parameters
    - system_prompt: The system prompt to provide context to the LLM
    - user_prompt: The user prompt containing the specific request
    - opts: Additional options specific to the LLM provider

  ## Returns
    - {:ok, content} if successful, where content is the LLM's response
    - {:error, reason} if an error occurred
  """
  @callback generate_completion(String.t(), String.t(), map()) ::
              {:ok, String.t()} | {:error, String.t()}

  @doc """
  Generate a completion with streaming enabled and callbacks.
  """
  @callback generate_streaming_completion(
              String.t(),
              String.t(),
              map(),
              map()
            ) :: {:ok, String.t()} | {:error, String.t()}
end
