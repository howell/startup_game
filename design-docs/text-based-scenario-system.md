# Text-Based Scenario System

## Overview

This document outlines the design for revising the scenario system to be text-based, making it more suitable for LLM integration. The key idea is to make specific choices an implementation detail of scenario providers rather than being built into the game engine.

## Current Issues

- The current system has fixed choices built into the `Scenario` struct
- The engine directly depends on specific scenario providers
- The response interpretation is separate from outcome generation

## Design Goals

- Make the game engine agnostic to how scenario providers implement choices
- Support free-form text responses from users
- Provide a clean interface for future LLM integration
- Maintain backward compatibility where possible

## Implementation Plan

### 1. Update the `ScenarioProvider` Behaviour

```elixir
@callback get_initial_scenario(GameState.t()) :: Scenario.t()
@callback get_next_scenario(GameState.t(), String.t()) :: Scenario.t() | nil
@callback generate_outcome(GameState.t(), Scenario.t(), String.t()) :: {:ok, map()} | {:error, String.t()}
```

- Remove the `interpret_response` callback
- Modify `generate_outcome` to take only the game state, scenario, and user response text
- Return either `{:ok, outcome}` or `{:error, error_message}`

### 2. Update the `Scenario` Module

```elixir
@type outcome :: %{
  text: String.t(),
  cash_change: Decimal.t(),
  burn_rate_change: Decimal.t(),
  ownership_changes: [GameState.ownership_change()] | nil,
  exit_type: :none | :acquisition | :ipo | :shutdown | nil,
  exit_value: Decimal.t() | nil
}
```

- Remove the `choice_id` field from the outcome type
- Keep the simplified Scenario struct with just id, type, and situation

### 3. Update the `Engine` Module

```elixir
def process_response(game_state, response_text) do
  scenario = game_state.current_scenario_data
  provider = game_state.scenario_provider

  # Clear any previous error message
  game_state = %{game_state | error_message: nil}

  # Generate outcome based on the response
  case provider.generate_outcome(game_state, scenario, response_text) do
    {:ok, outcome} ->
      # Process the outcome
      process_outcome(game_state, scenario, outcome, response_text)
    
    {:error, reason} ->
      # Add an error to the game state
      %{game_state | error_message: reason}
  end
end
```

- Remove the `process_choice` function or make it call `process_response` internally
- Create a new `process_outcome` function that handles the outcome processing
- Remove any direct dependencies on `StaticScenarioProvider`

### 4. Update the Scenario Providers

#### StaticScenarioProvider

```elixir
def generate_outcome(game_state, scenario, response_text) do
  # Try to match the response to a choice
  case match_response_to_choice(scenario.id, response_text) do
    {:ok, choice_id} ->
      # Get the predefined outcome for this choice
      outcome = get_outcome(scenario.id, choice_id)
      {:ok, outcome}
    
    {:error, reason} ->
      {:error, reason}
  end
end
```

- Implement internal choice matching logic
- Keep the predefined outcomes but as an implementation detail

#### DynamicScenarioProvider and LLMScenarioProvider

```elixir
def generate_outcome(game_state, scenario, response_text) do
  # Analyze the response and generate an appropriate outcome
  # This could use pattern matching, NLP, or an LLM
  
  # For now, use simple pattern matching
  cond do
    String.contains?(response_text, "accept") ->
      {:ok, generate_accept_outcome(response_text)}
    
    String.contains?(response_text, "negotiate") ->
      {:ok, generate_negotiate_outcome(response_text)}
    
    String.contains?(response_text, "decline") ->
      {:ok, generate_decline_outcome(response_text)}
    
    true ->
      {:error, "Could not determine your choice. Please try again with a clearer response."}
  end
end
```

- Implement response analysis logic specific to each provider
- Generate outcomes based on the response text directly

### 5. Update the GameRunner Module

```elixir
def make_response(game_state, response_text) do
  updated_state = Engine.process_response(game_state, response_text)
  
  # Check if there was an error processing the response
  if updated_state.error_message do
    # Return the same game state and situation, but with the error message
    situation = Engine.get_current_situation(updated_state)
    situation = Map.put(situation, :error, updated_state.error_message)
    {updated_state, situation}
  else
    # Process normally
    if updated_state.status == :in_progress && updated_state.current_scenario do
      situation = Engine.get_current_situation(updated_state)
      {updated_state, situation}
    else
      {updated_state, nil}  # Game has ended
    end
  end
end
```

- Simplify to just use `process_response`
- Remove or update `make_choice` to use `make_response` internally

## Implementation Sequence

1. Update the `Scenario` module to remove the `choice_id` field from the outcome type
2. Update the `ScenarioProvider` behaviour to modify the `generate_outcome` callback and remove `interpret_response`
3. Update the `Engine` module to use the new approach and remove dependencies on `StaticScenarioProvider`
4. Update the scenario providers to implement the new `generate_outcome` function
5. Update the `GameRunner` module to use the new approach
6. Run tests and fix any issues

## Flow Diagram

```mermaid
sequenceDiagram
    participant User
    participant GameRunner
    participant Engine
    participant ScenarioProvider
    
    User->>GameRunner: make_response(response_text)
    GameRunner->>Engine: process_response(response_text)
    Engine->>ScenarioProvider: generate_outcome(game_state, scenario, response_text)
    
    alt Successful response interpretation
        ScenarioProvider-->>Engine: {:ok, outcome}
        Engine->>Engine: process_outcome(game_state, scenario, outcome, response_text)
        Engine-->>GameRunner: updated_game_state
        GameRunner-->>User: {updated_state, next_situation}
    else Failed response interpretation
        ScenarioProvider-->>Engine: {:error, reason}
        Engine-->>GameRunner: game_state with error_message
        GameRunner-->>User: {state, situation with error}
    end