# Mobile Game State Panel Redesign

## Overview

This document outlines the plan to redesign the mobile game state panel in the Startup Game to make it more accessible and usable on mobile devices. The current implementation toggles between the game state panel and content area, preventing users from viewing both simultaneously.

The new design will position a condensed version of the game state panel between the chat history and the response form, allowing players to view critical game information while still interacting with the game.

## Goals

- Allow players to view game state information and chat interface simultaneously on mobile
- Display the most critical game state information (finances and ownership) by default
- Make the state panel expandable/collapsible vertically
- Move less critical information to a modal/panel for game settings within the main game page
- Maintain a consistent user experience across device sizes

## Implementation Plan

### 1. Component Structure Changes

#### Update `GameLayoutComponent`

- Modify the game layout component to support the new mobile state panel positioning
- Remove the current toggle button and full-screen mobile state panel
- Add a new condensed mobile state panel between chat history and response form
- Implement expand/collapse functionality for the panel

#### Create New Components

- `CondensedGameStatePanelComponent`: A simplified version of the game state panel
- `GameSettingsModalComponent`: A modal component for less critical game information that overlays the main game interface

### 2. UI/UX Design

#### Condensed Game State Panel

- Height: Collapsed state should be approximately 80-100px
- Expanded state should take up to 50% of the available vertical space
- Include an expand/collapse handle at the top of the panel
- In collapsed state, show summary information only:
  - Company name
  - Cash on hand
  - Runway
  - Ownership percentage (founder vs investors)
- In expanded state, show:
  - Detailed financial information
  - Complete ownership breakdown
  - Recent key metrics

#### Game Settings Modal

- Triggered via a settings button in the condensed game state panel
- Appears as a modal overlay on the game play page
- Contains:
  - Game visibility settings
  - Provider selector
  - Other configuration options
  - Recent events section
- Can be dismissed to return to the game without navigation

### 3. Layout & Styling

- Use CSS Grid or Flexbox for vertical layout on mobile:
  ```
  +---------------------------+
  |       Chat History        |
  |                           |
  +---------------------------+
  | ^ Condensed State Panel v |
  +---------------------------+
  |      Response Form        |
  +---------------------------+
  ```

- For the settings modal:
  ```
  +---------------------------+
  |    [ X ] Game Settings    |
  |                           |
  |      Modal Content        |
  |                           |
  |                           |
  |                           |
  +---------------------------+
  ```

- Add transition animations for expand/collapse and modal appearance
- Use consistent design language with the rest of the application
- Ensure all text is readable on small screens
- Make sure interactive elements are touch-friendly (min 44px touch targets)

### 4. State Management

- Add new state variables:
  - `is_mobile_panel_expanded`: Controls panel expansion state
  - `is_settings_modal_open`: Controls visibility of the settings modal
  - `active_settings_tab`: Tracks active tab in settings modal (if using tabs)
- Persist panel state in session storage for consistent UX across page refreshes

### 5. LiveView Event Handlers

- Implement handlers for:
  - `toggle_panel_expansion`: Expand/collapse the mobile state panel
  - `toggle_settings_modal`: Show/hide the game settings modal
  - `select_settings_tab`: Switch between tabs in the settings modal (if applicable)

### 6. Implementation Steps

1. Create new component files
   - `lib/startup_game_web/live/game_live/components/game_state/condensed_game_state_panel_component.ex`
   - `lib/startup_game_web/live/game_live/components/game_settings/game_settings_modal_component.ex`

2. Update existing components
   - Modify `lib/startup_game_web/live/game_live/components/shared/game_layout_component.ex`
   - Add new slots and attributes as needed
   - Add modal rendering logic to GamePlayComponent

3. Update CSS
   - Add new styles for condensed panel
   - Create modal styles with appropriate z-index and backdrop
   - Create transitions for expand/collapse and modal animations
   - Ensure touch-friendly controls

4. Update LiveView handlers
   - Add new event handlers to controller files
   - Add new state variables to socket assigns

5. Update chat interface to accommodate the new panel
   - Adjust responsive behavior of chat history and response form

### 7. Testing Approach

- Test on various device sizes (small phones to large tablets)
- Verify that critical information is visible in collapsed state
- Ensure expand/collapse functionality works smoothly
- Test modal appearance, interaction, and dismissal
- Validate that all game information is accessible
- Check that the chat interface remains usable with panel in expanded state
- Verify that the modal properly captures and releases focus

### 8. Accessibility Considerations

- Ensure expand/collapse controls have proper ARIA attributes
- Implement proper focus management for the modal
- Ensure the modal can be closed with ESC key
- Trap focus within modal when open
- Maintain proper contrast ratios for text
- Include clear visual indicators for interactive elements
- Ensure keyboard navigability for desktop users

## Technical Notes

### Component Dependencies

The new components will rely on:
- `GameStatePanelComponent` (existing)
- `FinancesComponent` (existing)
- `OwnershipComponent` (existing)
- `ModalComponent` (new or existing)

### CSS Classes

We'll need to add new Tailwind classes:
- `condensed-panel`: Base styles for the condensed panel
- `condensed-panel-expanded`: Styles for the expanded state
- `panel-handle`: Styles for the expand/collapse handle
- `settings-modal`: Styles for the settings modal
- `modal-backdrop`: Styles for the modal background overlay

### Expected LiveView Socket Assigns

```elixir
socket = assign(socket, 
  is_mobile_panel_expanded: false,  # New assign
  is_settings_modal_open: false,    # New assign
  active_settings_tab: "visibility" # New assign
)
```

## Follow-up Work

After implementation, we should consider:
- Adding animations to improve the user experience
- Creating custom visualizations for financial data in the condensed view
- Adding tooltips for condensed information
- Implementing swipe gestures for panel expansion 