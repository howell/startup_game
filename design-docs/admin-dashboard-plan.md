# Admin Dashboard Implementation Plan

This document outlines the plan for adding an administrator dashboard to the Startup Game application.

## Goals

*   Introduce privilege levels for users (initially `:user` and `:admin`).
*   Provide mechanisms for granting/rescinding admin privileges.
*   Create endpoints and UI accessible only to administrators.
*   Implement MVP features: User management (list, role change, delete), Game management (list, delete), and basic site statistics.

## Revised Plan

**Phase 1: Foundational Changes (Database & Authorization)**

1.  **Add Role to User Schema:**
    *   Create an Ecto migration using `mix phx.gen.schema` to add a `role` field to the `users` table.
    *   Use `Ecto.Enum` with values `:user` and `:admin`.
    *   Set the default value to `:user`.
    *   Update the `StartupGame.Accounts.User` schema (`lib/startup_game/accounts/user.ex`) to include the new `role` field and update the `@type t()` definition.

2.  **Implement Authorization Plug:**
    *   Create a new Plug module: `StartupGameWeb.Plugs.RequireAdminAuth`.
    *   This plug will inspect `conn.assigns.current_user.role`.
    *   If the role is not `:admin`, it will halt the connection and redirect non-admin users (e.g., to the home page with an error flash message).

**Phase 2: Admin Section Scaffolding**

3.  **Define Admin Routes & Pipeline:**
    *   In `lib/startup_game_web/router.ex`:
        *   Define a new pipeline `:admin_browser` that pipes through `:browser` and `StartupGameWeb.Plugs.RequireAdminAuth`.
        *   Create a new scope `/admin` that uses the `:admin_browser` pipeline.
        *   Add initial routes within the `/admin` scope for the dashboard landing page and management sections.

4.  **Create Basic Admin Dashboard UI:**
    *   Create a new LiveView: `StartupGameWeb.Admin.DashboardLive`.
    *   Create corresponding basic templates for the dashboard layout.

**Phase 3: Core Admin Features (MVP)**

5.  **User Management Backend (`StartupGame.Accounts`):**
    *   Add function `list_users()` to retrieve all users.
    *   Add function `get_user!(id)` (or similar) to fetch a single user.
    *   Add function `update_user_role(user, role)` to change a user's role.
    *   Add function `delete_user(user)` to delete a user account.

6.  **Game Management Backend (`StartupGame.Games`):**
    *   Add function `list_games()` to retrieve all games (consider pagination/filtering later if needed).
    *   Add function `delete_game(game)` to delete a game.

7.  **Statistics Backend (`Accounts`, `Games` contexts):**
    *   Add function `count_users()` to get the total user count.
    *   Add function `list_recent_users(limit \\ 5)` to get recently created users.
    *   Add function `count_games()` to get the total game count.
    *   Add function `list_recent_games(limit \\ 5)` to get recently created games.

8.  **Admin Dashboard UI:**
    *   Update `Admin.DashboardLive`:
        *   Fetch and display statistics (total users, recent users, total games, recent games).
        *   Provide links to User Management and Game Management pages.
    *   Create `Admin.UserManagementLive`:
        *   Display a list of users (email, username, role).
        *   Include controls (e.g., dropdown/buttons) to change user roles.
        *   Include controls (e.g., button with confirmation dialog) to delete users.
    *   Create `Admin.GameManagementLive`:
        *   Display a list of games (ID, owner, creation date, etc.).
        *   Include controls (e.g., button with confirmation dialog) to delete games.

**Phase 4: Initial Admin Setup**

9.  **Designate First Admin:**
    *   Implement a Mix task (e.g., `mix users.set_role <email> <role>`) to allow promoting an existing user to `:admin` via the command line.
    *   Plan to create a release task based on this Mix task for production deployments.

## Visual Plan (Mermaid Diagram)

```mermaid
graph TD
    A[Start: Add Admin Dashboard Request] --> B(Phase 1: Foundations);
    B --> B1(Add `role` field to User DB/Schema);
    B --> B2(Create `RequireAdminAuth` Plug);

    B1 --> C(Phase 2: Scaffolding);
    B2 --> C;
    C --> C1(Define Admin Pipeline & Scope in Router);
    C --> C2(Create Basic Admin Dashboard LiveView);

    C1 --> D(Phase 3: Core Features - MVP);
    C2 --> D;
    D --> D1(Implement `Accounts` functions: List, Update Role, Delete User);
    D --> D2(Implement `Games` functions: List, Delete Game);
    D --> D3(Implement Stats functions: User/Game Counts & Recents);
    D --> D4(Create User Management LiveView UI: List, Role Change, Delete);
    D --> D5(Create Game Management LiveView UI: List, Delete);
    D --> D6(Update Dashboard LiveView UI: Display Stats & Links);


    D1 --> E(Phase 4: Initial Setup);
    D2 --> E;
    D3 --> E;
    D4 --> E;
    D5 --> E;
    D6 --> E;
    E --> E1(Implement Mix Task for First Admin Creation);

    E1 --> F[End: Admin Dashboard MVP Ready];