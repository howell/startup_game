# Admin LiveView Test Suite Plan

This document outlines the plan for creating a comprehensive test suite for the admin LiveView components located in `lib/startup_game_web/live/admin/`.

## Target Components

*   `lib/startup_game_web/live/admin/dashboard_live.ex`
*   `lib/startup_game_web/live/admin/game_management_live.ex`
*   `lib/startup_game_web/live/admin/user_management_live.ex`

## Goals

*   Ensure core functionality of admin views works as expected.
*   Verify correct data display and interactions (role changes, deletions).
*   Establish robust test support utilities (fixtures, helpers) for maintainable tests.

## Plan Phases

### Phase 1: Enhance Test Support Utilities

1.  **Create Admin User Fixture:**
    *   **File:** `test/support/fixtures/accounts_fixtures.ex`
    *   **Action:** Define a new function `admin_user_fixture/1` that:
        *   Calls `user_fixture/1` to create a standard user.
        *   Uses `StartupGame.Accounts.update_user_role/2` to change the user's role to `:admin`.
        *   Returns the resulting admin user struct.
2.  **Add Admin Login Helper to `ConnCase`:**
    *   **File:** `test/support/conn_case.ex`
    *   **Action:** Define a new setup function `register_and_log_in_admin/1` that:
        *   Calls `AccountsFixtures.admin_user_fixture/1`.
        *   Calls the existing `log_in_user/2` function with the created admin user.
        *   Returns `%{conn: conn, admin_user: user}` for use in test contexts.

### Phase 2: Implement Test Suite

1.  **Create Test Files:**
    *   `test/startup_game_web/live/admin/dashboard_live_test.exs`
    *   `test/startup_game_web/live/admin/user_management_live_test.exs`
    *   `test/startup_game_web/live/admin/game_management_live_test.exs`
2.  **Write Tests (`DashboardLiveTest`):**
    *   Use `register_and_log_in_admin` setup.
    *   Test initial render: Check page title, header, presence of stat cards, management links, and recent user/game tables.
    *   Use fixtures (`admin_user_fixture`, `games_fixtures.game_fixture`) to create data and assert it appears correctly in the dashboard tables and stat counts.
3.  **Write Tests (`UserManagementLiveTest`):**
    *   Use `register_and_log_in_admin` setup.
    *   Test initial render: Check title, header, user table presence. Create admin and regular users; assert they appear correctly. Verify the logged-in admin cannot delete/modify their own role (buttons disabled/absent).
    *   Test role toggling: Find a regular user, click "Make Admin", assert flash/button text change, click "Make User", assert flash/button text change back.
    *   Test user deletion flow: Click delete, assert modal appears with correct user, test cancel, test confirm deletion (assert flash, modal closes, user removed from table).
4.  **Write Tests (`GameManagementLiveTest`):**
    *   Use `register_and_log_in_admin` setup.
    *   Test initial render: Check title, header, game table presence. Create games with different owners; assert they appear correctly.
    *   Test game deletion flow: Click delete, assert modal appears with correct game/owner, test cancel, test confirm deletion (assert flash, modal closes, game removed from table).
5.  **Implement Element Helper Functions (as needed within tests):**
    *   Create small, focused functions within each test module (or a shared helper module later if duplication becomes significant) to select elements based on stable identifiers (e.g., `find_user_row(view, user_id)`, `find_delete_button_for_row(row_element)`, `find_modal(view, "#delete-user-modal")`). This improves readability and resilience to minor UI tweaks.

## Mermaid Diagram

```mermaid
graph TD
    A[Start: Task Definition] --> B{Information Gathering};
    B --> B1[List Fixtures];
    B --> B2[Read accounts_fixtures.ex];
    B --> B3[Read accounts.ex];
    B --> B4[Read data_case.ex];
    B --> B5[Read conn_case.ex];
    B --> B6[Read user_auth.ex];
    B --> B7[Read require_admin_auth.ex];

    subgraph Phase 1: Test Support Utilities
        direction LR
        C[Define admin_user_fixture in accounts_fixtures.ex]
        D[Define register_and_log_in_admin in conn_case.ex]
    end

    B1 & B2 & B3 & B4 & B5 & B6 & B7 --> C;
    C --> D;

    subgraph Phase 2: Implement Test Suite
        direction TB
        E[Create Test Files];
        F[Write DashboardLive Tests];
        G[Write UserManagementLive Tests];
        H[Write GameManagementLive Tests];
        I[Implement Element Helpers (as needed)];
    end

    D --> E;
    E --> F;
    E --> G;
    E --> H;
    F & G & H --> I;


    I --> J{Plan Complete};