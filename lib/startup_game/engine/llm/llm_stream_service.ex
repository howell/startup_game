defmodule StartupGame.Engine.LLM.LLMStreamService do
  @moduledoc """
  GenServer that manages streaming LLM responses.

  This service handles the asynchronous streaming of LLM responses for both
  scenario generation and outcome generation. It maintains state for active
  streaming sessions and broadcasts updates to subscribers via PubSub.
  """
  use GenServer
  require Logger
  alias StartupGame.Engine.GameState
  alias StartupGame.Engine.LLM.JSONResponseParser
  alias StartupGame.Engine.LLM.ScenarioProviderCallback

  # Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Start generating a new scenario for the given game state.
  """
  @spec generate_scenario(
          String.t(),
          GameState.t(),
          String.t(),
          ScenarioProviderCallback.behaviour()
        ) ::
          {:ok, String.t()}
  def generate_scenario(game_id, game_state, current_scenario_id, provider_module) do
    GenServer.call(
      __MODULE__,
      {:generate_scenario, game_id, game_state, current_scenario_id, provider_module}
    )
  end

  @doc """
  Start generating a new outcome for the given game state.
  """
  @spec generate_outcome(
          String.t(),
          GameState.t(),
          map(),
          String.t(),
          ScenarioProviderCallback.behaviour()
        ) ::
          {:ok, String.t()}
  def generate_outcome(game_id, game_state, scenario, response_text, provider_module) do
    GenServer.call(
      __MODULE__,
      {:generate_outcome, game_id, game_state, scenario, response_text, provider_module}
    )
  end

  # Server Callbacks

  @impl true
  def init(_) do
    # State structure:
    # %{
    #   stream_id => %{
    #     game_id: String.t(),
    #     stream_type: :scenario | :outcome,
    #     partial_content: String.t(),      # Full content (includes JSON)
    #     display_content: String.t(),      # Only narrative part (for display)
    #     in_json_part: false,              # Whether we're in the JSON part
    #     scenario: map() | nil,
    #     response_text: String.t() | nil
    #   }
    # }
    {:ok, %{}}
  end

  @impl true
  def handle_call(
        {:generate_scenario, game_id, game_state, current_scenario_id, provider_module},
        _from,
        state
      ) do
    stream_id = generate_stream_id()

    # Initialize the stream state with new fields
    state =
      Map.put(state, stream_id, %{
        game_id: game_id,
        stream_type: :scenario,
        partial_content: "",       # Full content (includes JSON)
        display_content: "",       # Only narrative part (for display)
        in_json_part: false,       # Whether we're in the JSON part
        scenario: nil,
        response_text: nil
      })

    # Start the stream process asynchronously
    spawn_link(fn ->
      stream_scenario(stream_id, game_state, current_scenario_id, provider_module)
    end)

    # Return immediately with the stream_id
    {:reply, {:ok, stream_id}, state}
  end

  @impl true
  def handle_call(
        {:generate_outcome, game_id, game_state, scenario, response_text, provider_module},
        _from,
        state
      ) do
    stream_id = generate_stream_id()

    # Initialize the stream state with new fields
    state =
      Map.put(state, stream_id, %{
        game_id: game_id,
        stream_type: :outcome,
        partial_content: "",       # Full content (includes JSON)
        display_content: "",       # Only narrative part (for display)
        in_json_part: false,       # Whether we're in the JSON part
        scenario: scenario,
        response_text: response_text
      })

    # Start the stream process asynchronously
    spawn_link(fn ->
      stream_outcome(stream_id, game_state, scenario, response_text, provider_module)
    end)

    # Return immediately with the stream_id
    {:reply, {:ok, stream_id}, state}
  end

  # Helper function to process delta parts and track which part we're in
  defp process_delta_parts(current_display_content, delta_content, in_json_part) do
    # Check if this delta contains the delimiter
    if String.contains?(delta_content, "---JSON DATA---") do
      # Split at delimiter
      [narrative_part, _] = String.split(delta_content, "---JSON DATA---", parts: 2)
      {current_display_content <> narrative_part, true}
    else
      if in_json_part do
        # We're already in JSON part, don't add to display content
        {current_display_content, true}
      else
        # Still in narrative part
        {current_display_content <> delta_content, false}
      end
    end
  end

  @impl true
  def handle_cast({:stream_delta, stream_id, delta_content}, state) do
    # Retrieve the current stream state
    case Map.get(state, stream_id) do
      nil ->
        # If the stream_id doesn't exist (might have been completed already)
        Logger.warning("Received delta for unknown stream_id: #{stream_id}")
        {:noreply, state}

      stream_state ->
        # Update the partial content (full content for JSON parsing)
        updated_content = stream_state.partial_content <> delta_content

        # Process which part this belongs to
        {display_content, in_json_part} = process_delta_parts(
          stream_state.display_content,
          delta_content,
          stream_state.in_json_part
        )

        # Update the stream state
        updated_stream = %{
          stream_state |
          partial_content: updated_content,
          display_content: display_content,
          in_json_part: in_json_part
        }

        # Broadcast the delta (only narrative part changes)
        cond do
          !stream_state.in_json_part && !in_json_part ->
            # Still in narrative part, broadcast the delta
            StartupGameWeb.Endpoint.broadcast(
              "llm_stream:#{stream_state.game_id}",
              "llm_delta",
              {:llm_delta, stream_id, delta_content, display_content}
            )

          !stream_state.in_json_part && in_json_part ->
            # We just crossed into JSON part, broadcast one last update with just the narrative part
            narrative_part = String.split(delta_content, "---JSON DATA---", parts: 2) |> hd()

            if narrative_part != "" do
              StartupGameWeb.Endpoint.broadcast(
                "llm_stream:#{stream_state.game_id}",
                "llm_delta",
                {:llm_delta, stream_id, narrative_part, display_content}
              )
            end

          true ->
            # Already in JSON part, don't broadcast
            :ok
        end

        # Update the state
        {:noreply, Map.put(state, stream_id, updated_stream)}
    end
  end

  @impl true
  def handle_cast({:stream_complete, stream_id, full_content}, state) do
    # Retrieve the current stream state
    case Map.get(state, stream_id) do
      nil ->
        # If the stream_id doesn't exist (might have been completed already)
        Logger.warning("Received completion for unknown stream_id: #{stream_id}")
        {:noreply, state}

      stream_state ->
        # Process the completion and broadcast the result
        result = parse_completion(stream_state.stream_type, full_content)

        # Broadcast the completion to subscribers
        StartupGameWeb.Endpoint.broadcast(
          "llm_stream:#{stream_state.game_id}",
          "llm_complete",
          {:llm_complete, stream_id, result}
        )

        # Remove this stream from state
        {:noreply, Map.delete(state, stream_id)}
    end
  end

  @impl true
  def handle_cast({:stream_error, stream_id, error}, state) do
    # Retrieve the current stream state
    case Map.get(state, stream_id) do
      nil ->
        # If the stream_id doesn't exist
        Logger.warning("Received error for unknown stream_id: #{stream_id}")
        {:noreply, state}

      stream_state ->
        # Broadcast the error to subscribers
        StartupGameWeb.Endpoint.broadcast(
          "llm_stream:#{stream_state.game_id}",
          "llm_error",
          {:llm_error, stream_id, error}
        )

        # Remove this stream from state
        {:noreply, Map.delete(state, stream_id)}
    end
  end

  # Helper function to parse completion based on stream type
  defp parse_completion(:scenario, full_content) do
    case JSONResponseParser.parse_scenario(full_content) do
      {:ok, scenario} -> {:ok, scenario}
      {:error, reason} -> {:error, "Failed to parse scenario: #{reason}"}
    end
  end

  defp parse_completion(:outcome, full_content) do
    case JSONResponseParser.parse_outcome(full_content) do
      {:ok, outcome} -> {:ok, outcome}
      {:error, reason} -> {:error, "Failed to parse outcome: #{reason}"}
    end
  end

  # Private functions

  defp generate_stream_id do
    # Generate a unique ID for this stream
    "stream_" <> UUID.uuid4()
  end

  defp stream_scenario(stream_id, game_state, current_scenario_id, provider_module) do
    # Get configuration from the provider's callbacks
    adapter = provider_module.llm_adapter()
    llm_opts = Map.put(provider_module.llm_options(), :stream, true)
    system_prompt = provider_module.scenario_system_prompt()

    # Get the prompt from the provider's callback
    user_prompt = provider_module.create_scenario_prompt(game_state, current_scenario_id)

    # These will handle the streaming responses
    handlers = %{
      on_llm_new_delta: fn _model, %LangChain.MessageDelta{} = data ->
        # Forward the delta to our GenServer
        GenServer.cast(__MODULE__, {:stream_delta, stream_id, data.content})
      end,
      on_message_processed: fn _chain, %LangChain.Message{} = data ->
        # Forward the complete message to our GenServer
        GenServer.cast(__MODULE__, {:stream_complete, stream_id, data.content})
      end
    }

    # Generate the scenario with streaming
    try do
      case adapter.generate_streaming_completion(
             system_prompt,
             user_prompt,
             llm_opts,
             handlers
           ) do
        {:ok, _content} ->
          # Successful completion is handled by the callbacks
          :ok

        {:error, reason} ->
          # Forward the error to our GenServer
          GenServer.cast(__MODULE__, {:stream_error, stream_id, reason})
      end
    rescue
      e ->
        # Forward any exception to our GenServer
        GenServer.cast(__MODULE__, {:stream_error, stream_id, "LLM API error: #{inspect(e)}"})
    end
  end

  defp stream_outcome(stream_id, game_state, scenario, response_text, provider_module) do
    # Similar to stream_scenario but for outcomes
    adapter = provider_module.llm_adapter()
    llm_opts = Map.put(provider_module.llm_options(), :stream, true)
    system_prompt = provider_module.outcome_system_prompt()

    user_prompt = provider_module.create_outcome_prompt(game_state, scenario, response_text)

    handlers = %{
      on_llm_new_delta: fn _model, %LangChain.MessageDelta{} = data ->
        GenServer.cast(__MODULE__, {:stream_delta, stream_id, data.content})
      end,
      on_message_processed: fn _chain, %LangChain.Message{} = data ->
        GenServer.cast(__MODULE__, {:stream_complete, stream_id, data.content})
      end
    }

    try do
      case adapter.generate_streaming_completion(
             system_prompt,
             user_prompt,
             llm_opts,
             handlers
           ) do
        {:ok, _content} ->
          :ok

        {:error, reason} ->
          GenServer.cast(__MODULE__, {:stream_error, stream_id, reason})
      end
    rescue
      e ->
        GenServer.cast(__MODULE__, {:stream_error, stream_id, "LLM API error: #{inspect(e)}"})
    end
  end
end
