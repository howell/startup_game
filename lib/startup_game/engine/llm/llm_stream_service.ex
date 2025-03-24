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
  alias StartupGame.Utils

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
        # Full content (includes JSON)
        partial_content: "",
        # Only narrative part (for display)
        display_content: "",
        # Whether we're in the JSON part
        in_json_part: false,
        # Buffer for detecting split delimiters
        delimiter_buffer: "",
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
        # Full content (includes JSON)
        partial_content: "",
        # Only narrative part (for display)
        display_content: "",
        # Whether we're in the JSON part
        in_json_part: false,
        # Buffer for detecting split delimiters
        delimiter_buffer: "",
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

  # Define the delimiter as a module attribute for consistency
  @delimiter "---JSON DATA---"
  # @delimiter_length String.length(@delimiter)
  @delimiter_rx Utils.Regex.all_prefixes("---JSON DATA---", "$")

  # Helper function to process delta parts and track which part we're in
  @doc """
  Determine how much of the delta content definitely belongs to the narrative part vs JSON part.
  Arguents:
    - current_display_content: The current display content
    - delta_content: The new delta content
    - in_json_part: Whether we're already in the JSON part
    - delimiter_buffer: Buffer for detecting split delimiters
   Returns:
    - Tuple containing new display content, whether we're in JSON part, and the updated buffer
  """
  @spec process_delta_parts(
          String.t(),
          boolean(),
          String.t()
        ) ::
          {String.t(), boolean(), String.t()}
  def process_delta_parts(delta_content, in_json_part, delimiter_buffer) do
    # Update the buffer with new content, keeping only enough characters to detect the delimiter
    updated_buffer = delimiter_buffer <> delta_content

    cond do
      in_json_part ->
        # If we're already in JSON part, no need to check for delimiter
        {"", true, delimiter_buffer}

      String.contains?(updated_buffer, @delimiter) ->
        # Find where the delimiter starts in the buffer
        [narrative_part, _] = String.split(updated_buffer, @delimiter, parts: 2)

        {narrative_part, true, ""}

      true ->
        case check_suffix(updated_buffer) do
          [narrative_part, potential_delim, ""] ->
            {narrative_part, false, potential_delim}

          _ ->
            {updated_buffer, false, ""}
        end
    end
  end

  @spec check_suffix(String.t()) :: [String.t()]
  # check if the string ends with any prefix of the delimiter
  defp check_suffix(string) do
    Regex.split(@delimiter_rx, string, parts: 2, include_captures: true, trim: false)
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
        # Process the delta and update state
        updated_state = process_stream_delta(state, stream_id, stream_state, delta_content)
        {:noreply, updated_state}
    end
  end

  # Handle stream completion
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

  # Handle stream errors
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

  # Process a stream delta and update the state
  defp process_stream_delta(state, stream_id, stream_state, delta_content) do
    # Update the partial content (full content for JSON parsing)
    updated_content = stream_state.partial_content <> delta_content

    # Get the delimiter buffer from state or initialize it
    delimiter_buffer = Map.get(stream_state, :delimiter_buffer, "")

    # Process which part this belongs to with buffer
    {new_display_content, in_json_part, updated_buffer} =
      process_delta_parts(
        delta_content,
        stream_state.in_json_part,
        delimiter_buffer
      )

    to_display_so_far = stream_state.display_content <> new_display_content

    # Update the stream state
    updated_stream = %{
      stream_state
      | partial_content: updated_content,
        display_content: to_display_so_far,
        in_json_part: in_json_part,
        delimiter_buffer: updated_buffer
    }

    if new_display_content != "" do
      StartupGameWeb.Endpoint.broadcast(
        "llm_stream:#{stream_state.game_id}",
        "llm_delta",
        {:llm_delta, stream_id, new_display_content, to_display_so_far}
      )
    end

    # Update the state
    Map.put(state, stream_id, updated_stream)
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
