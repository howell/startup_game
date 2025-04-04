# Proactive Player Actions Implementation Plan

## 1. Overview

This document outlines the plan to modify the Startup Game engine and interface to allow players to take proactive actions (e.g., "Hire a salesperson") in addition to responding to game-provided situations. The goal is to give players more agency while maintaining a smooth gameplay flow.

## 2. Core Strategy

Introduce an explicit `player_mode` state (`:responding` or `:acting`) managed primarily in the frontend LiveView state. Buttons will allow the player to switch modes. The backend will respect this mode when deciding whether to automatically fetch the next scenario after an outcome. The mode will be persisted in the database to allow seamless game resumption.

## 3. Implementation Details

### 3.1 Database Migrations

1.  **Rename `response` column:**
    *   Generate: `mix ecto.gen.migration rename_round_response_to_player_input`
    *   Implement: `rename table(:rounds), :response, to: :player_input`
2.  **Add `player_mode` column:**
    *   Generate: `mix ecto.gen.migration add_player_mode_to_games`
    *   Implement: `alter table(:games) do add :current_player_mode, :string, default: "responding", null: false end`

### 3.2 Schemas

1.  **`Games.Game` (`lib/startup_game/games/game.ex`):**
    *   Add `:current_player_mode, :string` field to the schema.
2.  **`Engine.GameState` (`lib/startup_game/engine/game_state.ex`):**
    *   Rename the `:response` key to `:player_input` in the `@type round_entry :: %{...}` definition.

### 3.3 `ScenarioProvider` (`lib/startup_game/engine/scenario_provider.ex`)

*   Modify the *intent* of the `generate_outcome`/`generate_outcome_async` callbacks. They will receive the `current_scenario` (which could be `nil`) and the `player_input`. Their responsibility is to determine if the input is a response to the scenario *or* a proactive action, and generate an appropriate `Scenario.outcome`.
*   Update the `outcome_system_prompt` in `LLMScenarioProvider` to instruct the LLM to analyze the input's context (scenario vs. general game state) and generate outcomes for both reactive responses and proactive actions. Provide examples for both cases.

### 3.4 `Engine` (`lib/startup_game/engine/engine.ex`)

*   Extract outcome application logic into a new private function `apply_outcome_effects(game_state, outcome, player_input)`.
*   Rename `process_response` to `process_player_input(game_state, player_input)`. This function will call the provider's `generate_outcome` and then `apply_outcome_effects`.
*   Update `apply_outcome` (used by async flow) to call `apply_outcome_effects`.
*   Remove the old `process_outcome` function.
*   Add `clear_current_scenario(game_state)` function: returns `%{game_state | current_scenario: nil, current_scenario_data: nil}`.

### 3.5 `GameRunner` (`lib/startup_game/engine/game_runner.ex`)

*   Rename `make_response` to `process_input` and update its logic.
*   Remove/alias `make_choice`. Update `run_game`.

### 3.6 `GameService` (`lib/startup_game/game_service.ex`)

*   Rename `process_response*` functions to `process_player_input*`. Update internal calls to use the renamed `player_input` database field.
*   Modify `process_player_input` and `finalize_streamed_outcome` to return the `{:ok, %{game: ..., game_state: ...}}` result *without* automatically triggering the next round.
*   Add `request_next_scenario_async(game_id)`: Loads game state and calls `provider.get_next_scenario_async`.
*   Remove old round orchestration functions (`handle_progress`, `start_next_round_after_outcome`, `recover_next_scenario_async`, `start_next_round`).
*   Update `create_game`: Accept `initial_player_mode` (string, default `"responding"`), save to `games.current_player_mode`.
*   Update `load_game`: Load `current_player_mode` from DB into the `game` struct.
*   Add `update_player_mode(game_id, new_mode_string)` to update only the `current_player_mode` field in the DB.
*   Update `build_rounds_from_db`: Ensure it maps DB `player_input` to the renamed `GameState.round_entry` key.

### 3.7 Frontend (`play.ex`, Components, `StreamHandler`)

*   **State:** Add `assigns.player_mode` (`:responding` | `:acting`) to the `GameLive.Play` socket.
*   **Creation:** Add UI in `GameCreationComponent` to select starting mode ("Start with situation" / "Start acting"). Pass choice (`"responding"`/`"acting"`) to `GameService.create_game`.
*   **Loading:** `CreationHandler.handle_existing_game` initializes `assigns.player_mode` atom from loaded `game.current_player_mode` string.
*   **UI Elements:**
    *   Add "Take Initiative" button (visible when `mode == :responding` & scenario exists).
    *   Add "Await Next Situation" button (visible when `mode == :acting`).
    *   Input form always visible when game is in progress.
*   **Event Handlers (`GameLive.Play`):**
    *   `submit_response`: Calls `GameService.process_player_input_async`. Sets `streaming = true`, `streaming_type = :outcome`.
    *   `take_initiative`: Sets `assigns.player_mode = :acting`. Clears local scenario data. Calls `GameService.update_player_mode(game_id, "acting")`.
    *   `await_situation`: Sets `assigns.player_mode = :responding`. Calls `GameService.request_next_scenario_async`. Calls `GameService.update_player_mode(game_id, "responding")`. Sets `streaming = true`, `streaming_type = :scenario`.
*   **Stream Handling (`StreamHandler`):**
    *   `handle_complete(:outcome)`: Updates assigns with new state. **If `socket.assigns.player_mode == :responding`, it then calls `GameService.request_next_scenario_async`** and sets streaming state for scenario. If mode is `:acting`, it does nothing further.
    *   `handle_complete(:scenario)`: Updates assigns with new state (including scenario). Ensures `assigns.player_mode = :responding`. Calls `GameService.update_player_mode(game_id, "responding")`.
*   **UI Updates:** Conditionally render situation text and mode buttons based on `assigns.player_mode` and `assigns.game_state.current_scenario_data`. Update input placeholder.

### 3.8 Testing

*   Refactor existing tests for renamed functions/fields.
*   Add specific test cases simulating proactive player actions.
*   Add tests for mode switching logic in UI and backend interactions.
*   Add tests for persistence of `current_player_mode`.
*   Add tests for initial mode selection during game creation.

## 4. Flow Summary

*   **Situation Flow:** UI shows situation (`mode=:responding`). Player inputs response -> `process_player_input_async` -> Outcome stream completes -> `handle_complete(:outcome)` sees `mode=:responding` -> `request_next_scenario_async` -> Scenario stream completes -> `handle_complete(:scenario)` updates UI & persists mode -> Loop.
*   **Action Flow:** Player clicks "Take Initiative" -> UI updates (`mode=:acting`, situation hidden), mode persisted. Player inputs action -> `process_player_input_async` -> Outcome stream completes -> `handle_complete(:outcome)` sees `mode=:acting` -> **Stops here**. UI shows outcome, player remains in `mode=:acting`. Player can input another action or click "Await Next Situation".
*   **Switching Back:** Player clicks "Await Next Situation" -> Mode persisted, `request_next_scenario_async` called -> Scenario stream completes -> `handle_complete(:scenario)` updates UI, persists mode (`:responding`).
