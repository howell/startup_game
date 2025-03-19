# Game Creation Revision Plan

## Goal

Revise the way games are created to streamline the user interface and simplify testing. The initial scenario should be set *after* the game is created, rather than immediately when the game is created.

## Current Implementation

Currently, games are created with a name, initial description, and scenario provider via `StartupGame.Engine.new_game/3`. The scenario provider is then immediately queried to get the initial scenario. This is complicating testing, as seen in `StartupGame.GamesFixtures.complete_game_fixture/2`, where the first scenario will be the one from the scenario provider, not the round fixtures created in the function.

## Issues with Current Approach

1. **Tight Coupling**: Game creation and initial scenario setting are tightly coupled, making independent testing difficult.
2. **Inflexible ScenarioProvider**: The `ScenarioProvider` behavior has two separate callbacks: `get_initial_scenario/1` and `get_next_scenario/2`, adding complexity.
3. **Testing Difficulties**: Test fixtures have limited control over scenarios, as the first scenario is always automatically set.
4. **Lack of Step-by-Step Control**: The current design doesn't allow for more granular, piece-by-piece creation flow.

## Proposed Changes

### 1. Modify ScenarioProvider Behavior

```elixir
# Before
@callback get_initial_scenario(GameState.t()) :: Scenario.t()
@callback get_next_scenario(GameState.t(), String.t()) :: Scenario.t() | nil

# After
# Remove get_initial_scenario/1
@callback get_next_scenario(GameState.t(), String.t() | nil) :: Scenario.t() | nil
```

- Remove `get_initial_scenario/1` callback completely
- Enhance `get_next_scenario/2` to handle the case where the current scenario is `nil` (indicating it's the first scenario)

### 2. Update Engine Module

```elixir
# Before
def new_game(name, description, provider) do
  game_state = GameState.new(name, description)
  game_state = %{game_state | scenario_provider: provider}
  initial_scenario = provider.get_initial_scenario(game_state)
  %{game_state | current_scenario: initial_scenario.id, current_scenario_data: initial_scenario}
end

# After
def new_game(name, description, provider) do
  game_state = GameState.new(name, description)
  %{game_state | scenario_provider: provider}
end

# New function
def set_next_scenario(game_state) do
  provider = game_state.scenario_provider
  current_scenario_id = game_state.current_scenario
  next_scenario = provider.get_next_scenario(game_state, current_scenario_id)
  
  if next_scenario do
    %{game_state | current_scenario: next_scenario.id, current_scenario_data: next_scenario}
  else
    %{game_state | current_scenario: nil, current_scenario_data: nil, status: :completed}
  end
end
```

- Modify `new_game/3` to not query the provider for an initial scenario
- Add a new function `set_next_scenario/1` to explicitly set the next (or initial) scenario
- Update other relevant functions if necessary

### 3. Update GameService Module

```elixir
# Before
def start_game(name, description, %User{} = user, provider \\ StaticScenarioProvider) do
  game_state = Engine.new_game(name, description, provider)
  
  # Persist to database...
  
  # Create the initial round with the first scenario
  scenario = game_state.current_scenario_data
  
  {:ok, _} = Games.create_round(%{
    situation: scenario.situation,
    game_id: game.id
  })
  
  {:ok, %{game: game, game_state: game_state}}
end

# After
def start_game(name, description, %User{} = user, provider \\ StaticScenarioProvider) do
  # Create game state without scenario
  game_state = Engine.new_game(name, description, provider)
  
  # Set the first scenario
  game_state = Engine.set_next_scenario(game_state)
  
  # Persist to database...
  
  # Create the initial round with the first scenario
  scenario = game_state.current_scenario_data
  
  {:ok, _} = Games.create_round(%{
    situation: scenario.situation,
    game_id: game.id
  })
  
  {:ok, %{game: game, game_state: game_state}}
end
```

- Modify `start_game/4` to create a game first, then explicitly set the initial scenario
- Update `build_game_state_from_db/3` to use the new approach

### 4. Update GameRunner Module

```elixir
# Before
def start_game(name, description, provider) do
  game_state = Engine.new_game(name, description, provider)
  situation = Engine.get_current_situation(game_state)
  
  {game_state, situation}
end

# After
def start_game(name, description, provider) do
  game_state = Engine.new_game(name, description, provider)
  game_state = Engine.set_next_scenario(game_state)
  situation = Engine.get_current_situation(game_state)
  
  {game_state, situation}
end
```

- Update `start_game/3` to create a game and then explicitly set the initial scenario
- Update other functions that rely on the current behavior

### 5. Update Scenario Providers

All scenario provider implementations need to be updated to:
1. Remove `get_initial_scenario/1` implementation
2. Enhance `get_next_scenario/2` to handle `nil` current scenario ID

### 6. Update Tests and Fixtures

- Update `EngineTest` to use the new approach
- Modify `GamesFixtures`, particularly `complete_game_fixture/2`, to take advantage of the new flexibility

## Implementation Order

1. Modify the `ScenarioProvider` behavior
2. Update provider implementations
3. Modify the `Engine` module
4. Update the `GameService` and `GameRunner` modules
5. Fix tests and fixtures

## Testing Strategy

1. Run the existing test suite to identify failures after each change
2. Update failing tests to match the new behavior
3. Add new tests for the enhanced functionality
4. Verify all tests pass with `mix test`
5. Ensure code quality with `mix credo` and type checking with `mix dialyzer`

## Benefits

1. **Improved Testing**: Fixtures will have full control over scenarios
2. **Simplified Interface**: More intuitive API with better separation of concerns
3. **More Flexible**: Games can be created and modified step-by-step
4. **Reduced Complexity**: Simpler ScenarioProvider behavior