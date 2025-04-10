# Admin Training Game Interface - Implementation Plan

**Overall Goal:** Create an admin-only interface for playing, editing, and managing "training example" games to generate a dataset for LLM fine-tuning.

---

## Milestone 1: Data Model & Admin Foundation

*   **Goal:** Establish the necessary database schema changes and basic admin authorization infrastructure.
*   **Implementation:**
    1.  **Migration:** Create and run an Ecto migration to add `is_training_example` (boolean, default: false, null: false) to the `games` table.
    2.  **Migration:** Create and run an Ecto migration to add `scenario_system_prompt` (text, nullable) and `outcome_system_prompt` (text, nullable) to the `games` table.
    3.  **Schema Update:** Add the new fields (`:is_training_example`, `:scenario_system_prompt`, `:outcome_system_prompt`) to the `StartupGame.Games.Game` Ecto schema module (`lib/startup_game/games/game.ex`).
    4.  **Admin Role Check:** Verify the `StartupGame.Accounts.User` schema (`lib/startup_game/accounts/user.ex`) includes the `:role` field. Confirm the existence and functionality of the `StartupGameWeb.Plugs.RequireAdminAuth` plug (`lib/startup_game_web/plugs/require_admin_auth.ex`) to ensure it correctly checks if `conn.assigns.current_user.role == "admin"`.
    5.  **Router Setup:** Define an `/admin` scope in the Phoenix Router (`lib/startup_game_web/router.ex`) and apply the `RequireAdminAuth` plug to it. Add a placeholder route within this scope (e.g., `/admin/dashboard`) for initial testing.
*   **Testing:**
    *   **Migrations:** Run `mix ecto.migrate` and verify success. Inspect the database schema if necessary.
    *   **Schema:** Write basic unit tests for the `Game` schema ensuring the new fields exist and have correct types/defaults.
    *   **Authorization:**
        *   Use the `mix users.set_role <email> admin` task (assuming it exists based on file list) or `iex -S mix` to create/designate an admin user and a regular user.
        *   Write LiveView/Controller tests (or use manual browser testing) to:
            *   Confirm a non-admin user is redirected or receives an error when accessing `/admin/dashboard`.
            *   Confirm an admin user can successfully access `/admin/dashboard`.

---

## Milestone 2: Admin Dashboard & Training Game Listing

*   **Goal:** Create the main admin page to view existing training games.
*   **Implementation:**
    1.  **LiveView:** Create `lib/startup_game_web/live/admin/training_game_live/index.ex`.
    2.  **Routing:** Update the router to point `/admin/training_games` to `Admin.TrainingGameLive.Index`. Make this the primary admin landing page for now.
    3.  **Backend Logic:** Add a function in `StartupGame.Games` context (e.g., `list_training_games()`) to fetch all games where `is_training_example == true`.
    4.  **LiveView Mount:** In `mount/3` of the Index LiveView, call `Games.list_training_games()` and assign the result to the socket.
    5.  **LiveView Render:** Implement `render/1` to display a table showing the fetched training games (e.g., Name, Status). Include placeholder "Create New Training Game" and "Import Existing Game" buttons. Add links in the table rows (pointing to a future `/admin/training_games/:id/play` route).
*   **Testing:**
    *   **Manual Prep:** Create at least one regular game and one training game (set `is_training_example = true` manually via `iex -S mix`).
    *   **LiveView Tests:**
        *   Verify an admin user can mount the `/admin/training_games` page successfully.
        *   Verify the table only lists the game marked as `is_training_example`.
        *   Verify the presence of the buttons and links.

---

## Milestone 3: Create & Import Training Games

*   **Goal:** Enable admins to create new training games from scratch or by cloning existing games.
*   **Implementation:**
    1.  **Create Flow:**
        *   Create a component or use modal logic within `Admin.TrainingGameLive.Index` for the creation form.
        *   The form should include fields for Name, Description, Scenario System Prompt (textarea), and Outcome System Prompt (textarea). Pre-fill prompt textareas with defaults fetched from `StartupGame.Engine.LLMScenarioProvider`.
        *   Handle form submission: Call a new function in `StartupGame.Games` context (e.g., `create_training_game(attrs)`) that creates the game, setting `is_training_example = true` and saving the provided prompts. Redirect back to the index or to the new game's play page upon success.
    2.  **Import Flow:**
        *   Create a component or use modal logic for the import interface.
        *   Fetch and display a list/dropdown of existing *non-training* games (`is_training_example == false`).
        *   Implement the backend cloning function `StartupGame.Games.clone_game_as_training_example(source_game_id)` which performs a deep copy of the selected game and its associated rounds, ownerships, etc., setting `is_training_example = true` on the new game record.
        *   Handle selection: Call the cloning function and redirect to the newly created training game's play page.
*   **Testing:**
    *   **Create:**
        *   LiveView tests for the creation form (rendering, pre-filling prompts, validation, successful submission).
        *   Integration test verifying `Games.create_training_game/1` correctly persists the game with all attributes.
    *   **Import:**
        *   Unit tests for `Games.clone_game_as_training_example/1`, mocking Ecto calls or using `DataCase` to verify deep copying logic.
        *   LiveView tests for the import selection interface.
        *   Integration test: Create a regular game with several rounds/ownerships, import it, then query the DB to verify the new training game and all its associations were copied correctly.

---

## Milestone 4: Admin Play Interface (Read-only View)

*   **Goal:** Display the full history of a selected training game in a chat-like interface.
*   **Implementation:**
    1.  **LiveView:** Create `lib/startup_game_web/live/admin/training_game_live/play.ex`.
    2.  **Routing:** Define the route `/admin/training_games/:id/play` pointing to this LiveView.
    3.  **Backend Logic:** Enhance `StartupGame.Games` to fetch a game *with* its rounds preloaded (e.g., `get_training_game_with_history(id)`).
    4.  **LiveView Mount:** Fetch the specific training game and its history using the `:id` from the params.
    5.  **LiveView Render:** Adapt/reuse existing chat components (like `ChatHistory` if suitable) to display the sequence of rounds. Each round should clearly show the `situation` (if present), the `player_input`, and the `outcome` narrative. Handle empty states gracefully.
*   **Testing:**
    *   **LiveView Tests:**
        *   Verify mounting with a valid training game ID (including one with no rounds and one with multiple rounds).
        *   Verify correct rendering of the game history sequence.
        *   Verify it handles potential `nil` situations correctly.

---

## Milestone 5: Edit & Regenerate Outcome

*   **Goal:** Implement the core admin functionality: modifying the LLM's narrative/JSON outcome and triggering regeneration.
*   **Implementation:**
    1.  **LLM Provider Refactor:** Modify `StartupGame.Engine.LLMScenarioProvider` (or a wrapper module) to accept `scenario_system_prompt` and `outcome_system_prompt` as arguments to its functions, falling back to defaults if not provided. It also needs to accept the game history context.
    2.  **Edit UI:**
        *   In `Admin.TrainingGameLive.Play`, add an "Edit" button next to each round's outcome.
        *   Create `Admin.TrainingGameLive.EditOutcomeComponent`. On button click, render this component (e.g., modal) passing the `round` data.
        *   The component form should have: a textarea for `outcome` narrative, and inputs for `cash_change`, `burn_rate_change`, `ownership_changes` (potentially tricky UI - maybe JSON editor or structured fields), `exit_type`, `exit_value`. Pre-fill from the round.
        *   Handle component save: Send event to parent `Play` LiveView with updated round data (narrative + JSON fields).
        *   Parent LiveView calls a function in `StartupGame.Games` (e.g., `update_round_outcome(round, updates)`) to persist changes and refreshes the UI.
    3.  **Regenerate UI:**
        *   Add a "Regenerate" button next to each outcome.
        *   Handle button click in `Play` LiveView:
            *   Fetch the game's specific system prompts.
            *   Gather game history up to the *previous* round.
            *   Get the `player_input` for the *current* round.
            *   Call the refactored LLM provider function to generate a new outcome.
            *   Use `Games.update_round_outcome/2` to save the new narrative and JSON data to the current round.
            *   Refresh the UI.
*   **Testing:**
    *   **LLM Refactor:** Unit tests for the provider ensuring it uses passed prompts/history (mocking the actual LLM API call).
    *   **Edit:**
        *   LiveView tests for `EditOutcomeComponent` (rendering, form handling).
        *   LiveView tests for `Play` LiveView interaction (button click shows component, save event triggers update).
        *   Integration test for `Games.update_round_outcome/2`.
    *   **Regenerate:**
        *   LiveView tests for `Play` LiveView: Mock the LLM call, verify button click triggers the process, updates the round via `Games.update_round_outcome/2`, and refreshes UI.
        *   Manual test: Visually confirm regeneration works and replaces the outcome.

---

## Milestone 6: System Prompt Editing Interface

*   **Goal:** Allow admins to modify the system prompts used for a specific training game during playback.
*   **Implementation:**
    1.  **UI:** Add an "Edit Prompts" section/button/modal within the `Admin.TrainingGameLive.Play` interface.
    2.  **Form:** Display textareas for `scenario_system_prompt` and `outcome_system_prompt`, populated from the current `game` record fetched in `mount`.
    3.  **Handling:** On save, call a function in `StartupGame.Games` (e.g., `update_game_prompts(game, prompts)`) to update the fields on the `game` record. Refresh the prompt display in the UI.
*   **Testing:**
    *   **LiveView Tests:** Verify prompt display, form submission, and that the save triggers the correct update function call.
    *   **Integration Test:** Verify `Games.update_game_prompts/2` correctly persists changes.
    *   **Manual Test:** Edit prompts, then use "Regenerate" (Milestone 5) on a round to see if the LLM behavior changes accordingly.

---

## Milestone 7: Data Export (Future)

*   **Goal:** Provide a mechanism to export the curated training data.
*   **Implementation:** (Details deferred) Likely a Mix task (`mix training_data.export`) or a simple admin page that queries all training games/rounds and outputs JSONL.
*   **Testing:** (Details deferred) Unit/Integration tests for the export logic, manual verification of output.