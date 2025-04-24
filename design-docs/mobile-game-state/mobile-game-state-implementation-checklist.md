# Mobile Game State Panel Redesign Implementation Checklist

## Phase 1: Preparation and Planning

- [ ] Review current component structure and state management
- [ ] Identify all places in the codebase that reference:
  - [ ] `GameLayoutComponent`
  - [ ] Current mobile state panel toggling
  - [ ] Game state visibility logic
- [ ] Create branch for development (`feature/mobile-game-state-redesign`)
- [ ] Set up test environment with various mobile device sizes for testing

## Phase 2: Component Creation

### Create Condensed Game State Panel Component

- [x] Create file `lib/startup_game_web/live/game_live/components/game_state/condensed_game_state_panel_component.ex`
- [x] Implement collapsed view with:
  - [x] Company name display
  - [x] Cash on hand summary
  - [x] Runway indicator
  - [x] Ownership percentage breakdown
  - [x] Expand/collapse toggle
- [x] Implement expanded view with:
  - [x] Detailed financial information
  - [x] Full ownership breakdown
  - [x] Key metrics section
  - [x] Settings button to trigger modal
- [x] Add CSS for styling both states
- [x] Add expand/collapse animation with transition classes
- [x] Create helper functions for data formatting and calculations

### Create Game Settings Modal Component

- [x] Create file `lib/startup_game_web/live/game_live/components/game_settings/game_settings_modal_component.ex`
- [x] Implement modal shell with:
  - [x] Modal header with title and close button
  - [x] Tab navigation if using tabbed interface
  - [x] Modal backdrop with click-to-close functionality
  - [x] Close button and ESC key handling
- [x] Implement modal content sections:
  - [x] Game visibility settings
  - [x] Provider selector
  - [x] Recent events display
- [x] Add focus trapping for accessibility
- [x] Style modal with appropriate z-index and animations

## Phase 3: Update Existing Components

### Modify Game Layout Component

- [x] Update `lib/startup_game_web/live/game_live/components/shared/game_layout_component.ex`
- [x] Remove current mobile toggle button and full-screen panel
- [x] Modify layout structure to position condensed panel between chat and response form on mobile
- [x] Add new slot for condensed state panel
- [x] Add media queries for responsive behavior
- [x] Add z-index management for proper layering

### Update Game Play Component

- [x] Update `lib/startup_game_web/live/game_live/components/game_play_component.ex`
- [x] Add new socket assigns:
  - [x] `is_mobile_panel_expanded` (boolean, default false)
  - [x] `is_settings_modal_open` (boolean, default false)
  - [x] `active_settings_tab` (atom or string for tab navigation)
- [x] Add rendering logic for condensed panel
- [x] Add rendering logic for settings modal
- [x] Update existing assigns for proper panel state management

### Update Chat Interface Component

- [x] Modify `lib/startup_game_web/live/game_live/components/chat/chat_interface_component.ex`
- [x] Adjust chat history container to accommodate condensed panel
- [x] Ensure proper scrolling behavior when panel expands/collapses
- [x] Update response form positioning

## Phase 4: Event Handlers and State Management

- [x] Add event handler in LiveView for `toggle_panel_expansion`
  ```elixir
  def handle_event("toggle_panel_expansion", _, socket) do
    {:noreply, assign(socket, is_mobile_panel_expanded: !socket.assigns.is_mobile_panel_expanded)}
  end
  ```
- [x] Add event handler for `toggle_settings_modal`
  ```elixir
  def handle_event("toggle_settings_modal", _, socket) do
    {:noreply, assign(socket, is_settings_modal_open: !socket.assigns.is_settings_modal_open)}
  end
  ```
- [x] Add event handler for `select_settings_tab` if using tabs
  ```elixir
  def handle_event("select_settings_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_settings_tab: tab)}
  end
  ```
- [~] Implement session storage for panel state persistence
  - Event handlers are implemented in Play LiveView. Session storage for panel state persistence is in progress.

## Phase 5: CSS and Styling

- [ ] Create new CSS classes for condensed panel:
  - [ ] Base styles for collapsed state
  - [ ] Expanded state styles
  - [ ] Transition animations
  - [ ] Touch-friendly controls
- [ ] Create modal styles:
  - [ ] Modal backdrop with semi-transparency
  - [ ] Modal container with proper z-index
  - [ ] Modal animations for appear/disappear
  - [ ] Tab styling if using tabbed interface
- [ ] Update responsive breakpoints:
  - [ ] Ensure condensed panel only appears on mobile breakpoints
  - [ ] Full sidebar panel only on desktop breakpoints
- [ ] Add print media query to handle printing appropriately

## Phase 6: Testing

### Unit Tests

- [ ] Update tests for `GameLayoutComponent`:
  - [ ] Test desktop rendering with sidebar
  - [ ] Test mobile rendering with condensed panel
  - [ ] Test proper slot rendering
- [ ] Create tests for `CondensedGameStatePanelComponent`:
  - [ ] Test collapsed state rendering
  - [ ] Test expanded state rendering
  - [ ] Test data formatting
  - [ ] Test expand/collapse functionality
- [ ] Create tests for `GameSettingsModalComponent`:
  - [ ] Test modal rendering
  - [ ] Test modal open/close functionality
  - [ ] Test settings interaction
  - [ ] Test tab navigation if applicable
- [ ] Update tests for `GamePlayComponent`:
  - [ ] Test with new assigns
  - [ ] Test event handling
  - [ ] Test state persistence

### Integration Tests

- [ ] Test full game play flow on mobile:
  - [ ] Game creation
  - [ ] Panel expand/collapse
  - [ ] Settings modal open/close
  - [ ] Chat interaction with panel expanded
- [ ] Test responsive behavior:
  - [ ] Switching between mobile and desktop views
  - [ ] Verify correct component rendering at breakpoints
- [ ] Test modal interactions:
  - [ ] Verify modal backdrop blocks interaction with game
  - [ ] Verify ESC key closes modal
  - [ ] Verify focus trapping within modal

### Accessibility Testing

- [ ] Test keyboard navigation
- [ ] Test with screen readers
- [ ] Verify proper ARIA attributes
- [ ] Check color contrast meets standards
- [ ] Verify touch targets are large enough for mobile

## Phase 7: Documentation and Code Review

- [ ] Update component documentation:
  - [ ] Update `@moduledoc` for all modified components
  - [ ] Add `@doc` for all new functions
  - [ ] Add typespecs (`@spec`) for all new functions
- [ ] Document new assigns and their purposes
- [ ] Document event handlers and their behaviors
- [ ] Create pull request with detailed description of changes
- [ ] Conduct code review
- [ ] Address review feedback

## Phase 8: Deployment and Monitoring

- [ ] Deploy to staging environment
- [ ] Test on actual devices:
  - [ ] iOS Safari
  - [ ] Android Chrome
  - [ ] Tablet devices
- [ ] Monitor for errors or unexpected behavior
- [ ] Collect user feedback
- [ ] Make adjustments based on feedback
- [ ] Deploy to production

## Detailed Component Testing Checklist

### CondensedGameStatePanelComponent Tests

```elixir
defmodule StartupGameWeb.GameLive.Components.Game.CondensedGameStatePanelComponentTest do
  use StartupGameWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  
  alias StartupGameWeb.GameLive.Components.GameState.CondensedGameStatePanelComponent
  
  test "renders collapsed state properly" do
    # Test code
  end
  
  test "renders expanded state properly" do
    # Test code
  end
  
  test "formats financial data correctly" do
    # Test code
  end
  
  test "handles expand/collapse event" do
    # Test code
  end
  
  test "triggers settings modal when settings button clicked" do
    # Test code
  end
end
```

### GameSettingsModalComponent Tests

```elixir
defmodule StartupGameWeb.GameLive.Components.Game.GameSettingsModalComponentTest do
  use StartupGameWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  
  alias StartupGameWeb.GameLive.Components.GameSettings.GameSettingsModalComponent
  
  test "renders modal with correct content" do
    # Test code
  end
  
  test "closes when close button clicked" do
    # Test code
  end
  
  test "updates game settings when changed" do
    # Test code
  end
  
  test "switches tabs correctly when using tabbed interface" do
    # Test code
  end
end
```

### Updated GameLayoutComponent Tests

```elixir
defmodule StartupGameWeb.GameLive.Components.Shared.GameLayoutComponentTest do
  use StartupGameWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  
  alias StartupGameWeb.GameLive.Components.Shared.GameLayoutComponent
  
  test "renders desktop layout with sidebar" do
    # Test code
  end
  
  test "renders mobile layout with condensed panel" do
    # Test code
  end
  
  test "renders slot content correctly" do
    # Test code
  end
end
``` 