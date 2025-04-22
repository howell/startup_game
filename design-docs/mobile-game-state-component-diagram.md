# Mobile Game State Component Diagram

```
+------------------------------------------------------------------+
|                      GamePlayComponent                           |
+------------------------------------------------------------------+
                              |
                              | (uses)
                              ↓
+------------------------------------------------------------------+
|                      GameLayoutComponent                         |
+------------------------------------------------------------------+
            |                   |                   |
            | (slot)            | (slot)            | (slot)
            ↓                   ↓                   ↓
+-----------------------+ +---------------------+ +------------------+
|  GameStatePanelComp   | | ChatInterfaceComp   | | ResponseFormComp |
| (desktop only)        | |                     | |                  |
+-----------------------+ +---------------------+ +------------------+
            |                                          ↑
            | (only on mobile,                         |
            |  between chat and response)              |
            ↓                                          |
+-----------------------+                              |
| CondensedGameStateComp| (if expanded, takes space from chat)
+-----------------------+
            |
            | (triggers)
            ↓
+-----------------------+
|  GameSettingsModal    | <---- Overlays the main interface
| (modal component)     |       when triggered
+-----------------------+
```

## Component Responsibilities

### GameLayoutComponent
- Manages overall layout structure
- Handles responsive behavior
- Renders different components based on viewport size
- On mobile: places CondensedGameStateComponent between chat and response

### CondensedGameStatePanelComponent 
- Displays condensed game information in collapsed state
- Expands to show more detailed information when toggled
- Provides direct access to critical game state
- Contains a button to trigger the GameSettingsModal

### GameStatePanelComponent (existing)
- Used only on desktop views
- Shows complete game state information
- Fixed in sidebar position

### GameSettingsModalComponent
- Rendered as a modal overlay within the GamePlayComponent
- Contains all non-critical game information and settings
- Includes visibility toggles, provider selection, etc.
- Can be dismissed to return to the game interface
- Maintains its own internal state while open

## State Flow

```
+------------------------------------------------------------------+
|                     GamePlayComponent (LiveView)                  |
+------------------------------------------------------------------+
            |                       |                   |
            | (state)               | (state)           | (state)
            ↓                       ↓                   ↓
+------------------------+ +-------------------+ +------------------+
| is_mobile_panel_expanded| | is_settings_modal_open | active_settings_tab |
+------------------------+ +-------------------+ +------------------+
```

## User Interaction Flow

1. User loads game on mobile device
2. Condensed panel appears between chat history and response form
3. User can:
   - View basic information in collapsed panel
   - Expand panel to see detailed finances and ownership
   | Click "Settings" button to open the settings modal
   - Collapse panel to focus on chat
4. When settings modal is open:
   - User can modify settings
   - Modal overlays the main interface
   - User can close modal to return to game
   - No page navigation occurs
5. All game functionality remains accessible after closing the modal 