defmodule StartupGame.Test.Helpers.Streaming do
  @moduledoc """
  Provides helper macros for testing interactions with streaming.
  """

  import ExUnit.Assertions

  @doc """
  Asserts that the current process receives an `:llm_complete` message
  matching the provided patterns.

  ## Arguments

    * `result_pattern` (optional): The pattern to match against the `result` part of the message. Defaults to `_`.
    * `stream_id_pattern` (optional): The pattern to match against the `stream_id`. Defaults to `_`.
    * `timeout` (optional): The timeout for `assert_receive`. Defaults to `5000` ms.

  ## Examples

      # Assert a successful completion with any stream_id
      assert_stream_complete({:ok, %{content: "Expected response"}})

      # Assert a successful completion with a specific stream_id
      assert_stream_complete({:ok, _}, "specific_stream_123")

      # Assert an error completion with a specific timeout
      assert_stream_complete({:error, _reason}, _, 10000)

  """
  defmacro assert_stream_complete(
             result_pattern \\ quote(do: _),
             stream_id_pattern \\ quote(do: _),
             timeout \\ 100
           ) do
    quote do
      assert_receive %{
                       event: "llm_complete",
                       payload:
                         {:llm_complete, unquote(stream_id_pattern), unquote(result_pattern)}
                     },
                     unquote(timeout)
    end
  end
end
