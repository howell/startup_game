defmodule StartupGame.Engine.LLM.BaseScenarioProvider do
  @moduledoc """
  Base module for LLM-powered scenario providers.

  This module provides common functionality and implementations for LLM scenario providers.
  It can be used by specific provider implementations via the `use` macro.
  """

  alias StartupGame.Engine.GameState
  alias StartupGame.Engine.LLM.LLMStreamService

  @doc """
  When used, defines an LLM-based scenario provider.

  This macro:
  1. Implements the ScenarioProvider behavior
  2. Adds the LLMScenarioProviderCallback behavior
  3. Provides default implementations for optional callbacks

  ## Example

  ```elixir
  defmodule MyProvider do
    use StartupGame.Engine.LLM.BaseScenarioProvider

    # Required callbacks
    def llm_adapter, do: MyLLMAdapter
    def scenario_system_prompt, do: "System prompt for scenarios..."
    def outcome_system_prompt, do: "System prompt for outcomes..."

    # Optional callbacks - can be omitted to use defaults
    def llm_options, do: %{model: "my-model"}
  end
  ```
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour StartupGame.Engine.ScenarioProvider
      @behaviour StartupGame.Engine.LLM.ScenarioProviderCallback

      # Implement the ScenarioProvider callbacks
      @impl StartupGame.Engine.ScenarioProvider
      def get_next_scenario(game_state, current_scenario_id) do
        StartupGame.Engine.LLM.BaseScenarioProvider.get_next_scenario_impl(
          game_state,
          current_scenario_id,
          __MODULE__
        )
      end

      @impl StartupGame.Engine.ScenarioProvider
      def get_next_scenario_async(game_state, game_id, current_scenario_id) do
        StartupGame.Engine.LLM.BaseScenarioProvider.get_next_scenario_async_impl(
          game_state,
          game_id,
          current_scenario_id,
          __MODULE__
        )
      end

      @impl StartupGame.Engine.ScenarioProvider
      def generate_outcome(game_state, scenario, response_text) do
        StartupGame.Engine.LLM.BaseScenarioProvider.generate_outcome_impl(
          game_state,
          scenario,
          response_text,
          __MODULE__
        )
      end

      @impl StartupGame.Engine.ScenarioProvider
      def generate_outcome_async(game_state, game_id, scenario, response_text) do
        StartupGame.Engine.LLM.BaseScenarioProvider.generate_outcome_async_impl(
          game_state,
          game_id,
          scenario,
          response_text,
          __MODULE__
        )
      end

      # Default implementations for optional callbacks

      @impl StartupGame.Engine.LLM.ScenarioProviderCallback
      def llm_options, do: %{}

      @impl StartupGame.Engine.LLM.ScenarioProviderCallback
      def response_parser, do: StartupGame.Engine.LLM.JSONResponseParser

      @impl StartupGame.Engine.LLM.ScenarioProviderCallback
      def create_scenario_prompt(game_state, current_scenario_id) do
        StartupGame.Engine.LLM.BaseScenarioProvider.default_scenario_prompt(
          game_state,
          current_scenario_id
        )
      end

      @impl StartupGame.Engine.LLM.ScenarioProviderCallback
      def create_outcome_prompt(game_state, scenario, response_text) do
        StartupGame.Engine.LLM.BaseScenarioProvider.default_outcome_prompt(
          game_state,
          scenario,
          response_text
        )
      end

      @impl StartupGame.Engine.LLM.ScenarioProviderCallback
      def should_end_game?(game_state) do
        StartupGame.Engine.LLM.BaseScenarioProvider.default_should_end_game?(game_state)
      end

      defoverridable StartupGame.Engine.LLM.ScenarioProviderCallback
    end
  end

  @doc """
  Main implementation of get_next_scenario that's used by all providers.
  """
  def get_next_scenario_impl(game_state, current_scenario_id, provider_module) do
    # Check if the game should end using the provider's callback
    if provider_module.should_end_game?(game_state) do
      nil
    else
      # Get configuration from the provider's callbacks
      llm_module = provider_module.llm_adapter()
      llm_opts = provider_module.llm_options()
      system_prompt = provider_module.scenario_system_prompt()
      response_parser = provider_module.response_parser()

      # Get the prompt from the provider's callback
      user_prompt = provider_module.create_scenario_prompt(game_state, current_scenario_id)

      # Generate the scenario
      case generate_llm_scenario(
             llm_module,
             system_prompt,
             user_prompt,
             llm_opts,
             response_parser
           ) do
        {:ok, scenario} -> scenario
        {:error, reason} -> raise "Failed to generate LLM scenario: #{reason}"
      end
    end
  end

  @doc """
  Default implementation of get_next_scenario_async.
  """
  def get_next_scenario_async_impl(game_state, game_id, _current_scenario_id, provider_module) do
    LLMStreamService.generate_scenario(
      game_id,
      game_state,
      game_state.current_scenario,
      provider_module
    )
  end

  @doc """
  Main implementation of generate_outcome that's used by all providers.
  """
  def generate_outcome_impl(game_state, scenario, response_text, provider_module) do
    # Get configuration from the provider's callbacks
    llm_module = provider_module.llm_adapter()
    llm_opts = provider_module.llm_options()
    system_prompt = provider_module.outcome_system_prompt()
    response_parser = provider_module.response_parser()

    # Get the prompt from the provider's callback
    user_prompt = provider_module.create_outcome_prompt(game_state, scenario, response_text)

    # Generate the outcome
    case generate_llm_outcome(
           llm_module,
           system_prompt,
           user_prompt,
           llm_opts,
           response_parser
         ) do
      {:ok, outcome} -> {:ok, outcome}
      {:error, reason} -> raise "Failed to generate LLM outcome: #{reason}"
    end
  end

  @doc """
  Main implementation of generate_outcome_async that's used by all providers.
  """
  def generate_outcome_async_impl(game_state, game_id, scenario, response_text, provider_module) do
    LLMStreamService.generate_outcome(
      game_id,
      game_state,
      scenario,
      response_text,
      provider_module
    )
  end

  @doc """
  Default implementation for creating a scenario prompt.
  """
  def default_scenario_prompt(game_state, current_scenario_id) do
    # Format the game history
    history = format_game_history(game_state)

    # Format the ownership structure
    ownership = format_ownership_structure(game_state.ownerships)

    # Calculate the runway
    runway = GameState.calculate_runway(game_state)

    # Create the prompt
    """
    Startup: "#{game_state.name}" in #{game_state.description}

    Current state:
    - Cash on hand: $#{game_state.cash_on_hand}
    - Burn rate: $#{game_state.burn_rate} per month
    - Runway: #{runway} months
    - Ownership: #{ownership}

    #{if is_nil(current_scenario_id), do: "This is the first scenario for this startup.", else: ""}

    Game history:
    #{history}
    """
  end

  @doc """
  Default implementation for creating an outcome prompt.
  """
  def default_outcome_prompt(game_state, scenario, response_text) do
    # Format the ownership structure
    ownership = format_ownership_structure(game_state.ownerships)

    # Calculate the runway
    runway = GameState.calculate_runway(game_state)

    # Create the prompt
    """
    Startup: "#{game_state.name}" in #{game_state.description}

    Current state:
    - Cash on hand: $#{game_state.cash_on_hand}
    - Burn rate: $#{game_state.burn_rate} per month
    - Runway: #{runway} months
    - Ownership: #{ownership}


    #{if scenario, do: "Scenario presented to the player:\n #{scenario.situation}", else: ""}

    Player's action/response:
    #{response_text}
    """
  end

  @doc """
  Default implementation for determining if the game should end.
  """
  def default_should_end_game?(game_state) do
    # End the game if:
    # - Cash is too low
    # - Runway is less than 1 month
    # - We've played too many rounds (as a safety)
    # - The game has already exited
    length(game_state.rounds) >= 15 or
      Decimal.compare(game_state.cash_on_hand, Decimal.new("0")) == :lt or
      Decimal.compare(GameState.calculate_runway(game_state), Decimal.new("1")) == :lt or
      game_state.exit_type != :none
  end

  @doc """
  Formats the game history for inclusion in prompts.
  """
  @spec format_game_history(GameState.t()) :: String.t()
  def format_game_history(%GameState{rounds: []}), do: "Founded"

  def format_game_history(game_state) do
    game_state.rounds
    |> Enum.with_index(1)
    |> Enum.map_join("\n\n", fn {round, index} ->
      financial_impact = if round.cash_change, do: "$#{round.cash_change}", else: "None"

      """
      Round #{index}:
      Situation: #{round.situation}
      Response: #{round.player_input || "No response"}
      Outcome: #{round.outcome || "No outcome"}
      Financial impact: #{financial_impact}
      """
    end)
  end

  @doc """
  Formats the ownership structure for inclusion in prompts.
  """
  def format_ownership_structure(ownerships) do
    ownerships
    |> Enum.map_join(", ", fn %{entity_name: name, percentage: percentage} ->
      "#{name}: #{percentage}%"
    end)
  end

  # Core LLM functions

  @doc """
  Generates a scenario using the LLM.
  """
  def generate_llm_scenario(llm_module, system_prompt, user_prompt, llm_opts, response_parser) do
    # Call the LLM adapter to generate text
    case llm_module.generate_completion(system_prompt, user_prompt, llm_opts) do
      {:ok, content} ->
        # Parse the response
        response_parser.parse_scenario(content)

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Generates an outcome using the LLM.
  """
  def generate_llm_outcome(llm_module, system_prompt, user_prompt, llm_opts, response_parser) do
    # Call the LLM adapter to generate text
    case llm_module.generate_completion(system_prompt, user_prompt, llm_opts) do
      {:ok, content} ->
        # Parse the response
        response_parser.parse_outcome(content)

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Parses a scenario type string into the corresponding atom.
  """
  def parse_scenario_type(type_str) do
    case String.downcase(type_str) do
      "funding" -> :funding
      "acquisition" -> :acquisition
      "hiring" -> :hiring
      "legal" -> :legal
      _ -> :other
    end
  end

  @doc """
  Parses a value into a Decimal.
  """
  def parse_decimal(value) when is_integer(value) or is_float(value) do
    Decimal.from_float(value / 1)
  end

  def parse_decimal(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, _} -> decimal
      _ -> Decimal.new("0")
    end
  end

  def parse_decimal(_), do: Decimal.new("0")

  @doc """
  Parses ownership changes from the LLM response.
  """
  def parse_ownership_changes(nil), do: nil

  def parse_ownership_changes(changes) when is_list(changes) do
    Enum.map(changes, fn change ->
      %{
        entity_name: Map.get(change, "entity_name", "Unknown"),
        percentage_delta: parse_decimal(Map.get(change, "percentage_delta", "0"))
      }
    end)
  end

  def parse_ownership_changes(_), do: nil

  @doc """
  Parses an exit type string into the corresponding atom.
  """
  def parse_exit_type(type_str) do
    case String.downcase(type_str) do
      "acquisition" -> :acquisition
      "ipo" -> :ipo
      "shutdown" -> :shutdown
      _ -> :none
    end
  end

  @doc """
  Parses an exit value from the LLM response.
  """
  def parse_exit_value(_, "none"), do: nil
  def parse_exit_value(nil, _), do: Decimal.new("0")
  def parse_exit_value(value, _), do: parse_decimal(value)
end
