# Leaderboard Implementation

## 1. Overview

The leaderboard functionality displays the most successful games in the system, allowing users to view and sort games by exit value and founder yield. It consists of two main components:

1. **LeaderboardWidget** - A compact widget that shows the top startup exits, designed to be embedded in other pages
2. **LeaderboardLive** - A full page view with detailed information and interactive sorting

The leaderboard has been implemented as a public feature, accessible to both authenticated and non-authenticated users.

## 2. Data Model and Backend Implementation

### 2.1 Backend Enhancements

We've enhanced the Games context with new functions to support leaderboard functionality:

```elixir
# lib/startup_game/games.ex

def list_leaderboard_data(params \\ %{}) do
  sort_by = Map.get(params, :sort_by, "exit_value")
  sort_direction = Map.get(params, :sort_direction, :desc)
  limit = Map.get(params, :limit, 50)
  
  # Get eligible games with users and ownerships
  games =
    Game
    |> where([g], g.is_public == true and g.is_leaderboard_eligible == true)
    |> where([g], g.status == :completed)
    |> where([g], g.exit_type in [:acquisition, :ipo])
    |> preload([:user, :ownerships])
    |> order_by([g], [{^sort_direction, field(g, ^String.to_atom(sort_by))}])
    |> limit(^limit)
    |> Repo.all()
  
  # Format the data, calculate yields
  Enum.map(games, fn game ->
    founder_yield = calculate_founder_yield(game)
    
    %{
      username: game.user.email |> String.split("@") |> hd(),
      company_name: game.name,
      exit_value: game.exit_value,
      yield: founder_yield,
      user_id: game.user_id
    }
  end)
end

# Helper to calculate founder yield based on ownership
defp calculate_founder_yield(game) do
  # Find the founder's ownership
  founder_ownership = 
    Enum.find(game.ownerships, fn ownership -> 
      ownership.entity_name == "Founder" 
    end)
  
  # Calculate yield based on percentage
  if founder_ownership do
    percentage = Decimal.div(founder_ownership.percentage, Decimal.new(100))
    Decimal.mult(game.exit_value, percentage)
  else
    # Default if no founder record found
    Decimal.mult(game.exit_value, Decimal.new("0.5"))
  end
end
```

These functions:
- Select only completed games with successful exits (acquisition or IPO)
- Filter for games that are both public and leaderboard eligible
- Calculate the founder's yield based on their ownership percentage
- Support custom sorting (by exit value or yield) and limiting

### 2.2 Existing Game Model

The leaderboard functionality leverages the existing Game schema, which already included:

- `is_public` - Boolean indicating if the game is visible to other users
- `is_leaderboard_eligible` - Boolean indicating if the game should appear on leaderboards
- `exit_value` - The value of the company upon exit (acquisition/IPO)
- `exit_type` - Type of exit (acquisition/IPO/shutdown)

The `Ownership` schema is used to calculate the founder's yield (percentage of exit value).

## 3. Frontend Implementation

### 3.1 LeaderboardWidget Component

We created a compact widget for displaying the top startup exits:

```elixir
# lib/startup_game_web/components/leaderboard_widget.ex

defmodule StartupGameWeb.LeaderboardWidget do
  use StartupGameWeb, :html
  import StartupGameWeb.CoreComponents
  alias StartupGame.Games

  attr :class, :string, default: ""
  attr :limit, :integer, default: 5

  def leaderboard(assigns) do
    # Fetch real leaderboard data
    leaderboard_data = Games.list_leaderboard_data(%{limit: assigns.limit})
    
    assigns = assign(assigns, :leaderboard_data, leaderboard_data)
    
    ~H"""
    <div class={"rounded-xl shadow-md overflow-hidden bg-white #{@class}"}>
      <div class="px-4 py-4 bg-silly-blue/10">
        <div class="flex justify-between items-center">
          <h3 class="font-bold text-gray-900">Top Startup Exits</h3>
          <a href="/leaderboard" class="text-silly-blue hover:text-silly-blue/80 text-sm font-medium">
            View All
          </a>
        </div>
      </div>
      
      <div class="overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th
                scope="col"
                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Rank
              </th>
              <th
                scope="col"
                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Username
              </th>
              <th
                scope="col"
                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Company
              </th>
              <th
                scope="col"
                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Exit Value
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <%= for {entry, index} <- Enum.with_index(@leaderboard_data) do %>
              <tr class="hover:bg-gray-50">
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="text-sm font-medium text-gray-900"><%= index + 1 %></div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="text-sm font-medium text-gray-900">@<%= entry.username %></div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="text-sm font-medium text-gray-900"><%= entry.company_name %></div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="text-sm text-gray-900 font-medium">
                    $<%= format_number(entry.exit_value) %>
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
  
  # Helper function to format large numbers with commas
  defp format_number(number) do
    number
    |> Decimal.to_string()
    |> String.replace(~r/(\d)(?=(\d{3})+(?!\d))/, "\\1,")
  end
end
```

Key features:
- Shows configurable number of top games (default: 5)
- Displays username, company name, and exit value
- Links to the full leaderboard page
- Responsive design with consistent styling

### 3.2 LeaderboardLive Component

We implemented a full page leaderboard with interactive sorting:

```elixir
# lib/startup_game_web/live/leaderboard_live.ex

defmodule StartupGameWeb.LeaderboardLive do
  use StartupGameWeb, :live_view
  alias StartupGame.Games
  import StartupGameWeb.Components.Home.Navbar
  import StartupGameWeb.Components.Home.Footer

  def mount(_params, _session, socket) do
    # Fetch real leaderboard data
    leaderboard_data = Games.list_leaderboard_data(%{sort_by: "exit_value"})

    {:ok, assign(socket,
      page_title: "Leaderboard",
      leaderboard_data: leaderboard_data,
      sort_by: "exit_value", # Default sort
      sort_direction: :desc
    )}
  end

  def handle_event("sort", %{"field" => field}, socket) do
    current_field = socket.assigns.sort_by
    current_direction = socket.assigns.sort_direction
    
    # If clicking the same field, toggle direction; otherwise, use desc
    {new_field, new_direction} = if field == current_field do
      {field, if(current_direction == :desc, do: :asc, else: :desc)}
    else
      {field, :desc}
    end
    
    # Get fresh data with new sort
    sorted_data = Games.list_leaderboard_data(%{
      sort_by: new_field,
      sort_direction: new_direction
    })
    
    {:noreply, assign(socket,
      leaderboard_data: sorted_data,
      sort_by: new_field,
      sort_direction: new_direction
    )}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <.navbar id="leaderboard-navbar" current_user={@current_user} />
      
      <main class="pt-20 pb-10">
        <div class="container mx-auto px-4">
          <div class="flex flex-col items-center mb-8">
            <h1 class="text-3xl font-bold text-gray-900 mb-2">Startup Success Leaderboard</h1>
            <p class="text-gray-600 text-center max-w-2xl">
              See the most successful founders and their companies in SillyConValley.
              Sort by either exit value or founder yield to discover different success stories.
            </p>
          </div>
          
          <div class="bg-white rounded-xl shadow-md overflow-hidden">
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-100">
                  <tr>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Rank
                    </th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Username
                    </th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Company
                    </th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer group" phx-click="sort" phx-value-field="exit_value">
                      <div class="flex items-center">
                        Exit Value
                        <span class={"ml-1 text-silly-blue transition-all duration-200 #{if @sort_by == "exit_value", do: "opacity-100", else: "opacity-0 group-hover:opacity-50"}"}>
                          <%= cond do %>
                            <% @sort_by == "exit_value" && @sort_direction == :desc -> %>
                              <.icon name="hero-chevron-down" class="h-4 w-4" />
                            <% @sort_by == "exit_value" && @sort_direction == :asc -> %>
                              <.icon name="hero-chevron-up" class="h-4 w-4" />
                            <% true -> %>
                              <.icon name="hero-chevron-down" class="h-4 w-4" />
                          <% end %>
                        </span>
                      </div>
                    </th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer group" phx-click="sort" phx-value-field="yield">
                      <div class="flex items-center">
                        Founder Yield
                        <span class={"ml-1 text-silly-blue transition-all duration-200 #{if @sort_by == "yield", do: "opacity-100", else: "opacity-0 group-hover:opacity-50"}"}>
                          <%= cond do %>
                            <% @sort_by == "yield" && @sort_direction == :desc -> %>
                              <.icon name="hero-chevron-down" class="h-4 w-4" />
                            <% @sort_by == "yield" && @sort_direction == :asc -> %>
                              <.icon name="hero-chevron-up" class="h-4 w-4" />
                            <% true -> %>
                              <.icon name="hero-chevron-down" class="h-4 w-4" />
                          <% end %>
                        </span>
                      </div>
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= for {entry, index} <- Enum.with_index(@leaderboard_data) do %>
                    <tr class={"#{if rem(index, 2) == 0, do: "bg-white", else: "bg-gray-50"} hover:bg-gray-100 transition-colors duration-150"}>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900 font-medium"><%= index + 1 %></div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <div class="h-10 w-10 rounded-full bg-silly-purple text-white flex items-center justify-center font-bold">
                            <%= String.upcase(String.slice(entry.username, 0, 1)) %>
                          </div>
                          <div class="ml-4">
                            <div class="text-sm font-medium text-gray-900">@<%= entry.username %></div>
                          </div>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900"><%= entry.company_name %></div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900 font-semibold">
                          $<%= format_number(entry.exit_value) %>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900 font-semibold">
                          $<%= format_number(entry.yield) %>
                        </div>
                        <div class="text-xs text-gray-500">
                          <%= calculate_percentage(entry.yield, entry.exit_value) %>% of exit
                        </div>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
          
          <div class="mt-8 flex justify-center">
            <a href="/" class="text-silly-blue hover:text-silly-blue/80 font-medium flex items-center">
              <.icon name="hero-arrow-left" class="h-4 w-4 mr-2" />
              Back to Home
            </a>
          </div>
        </div>
      </main>
      
      <.footer />
    </div>
    """
  end
  
  # Helper function to format large numbers with commas
  defp format_number(number) do
    number
    |> Decimal.to_string()
    |> String.replace(~r/(\d)(?=(\d{3})+(?!\d))/, "\\1,")
  end
  
  # Helper function to calculate percentage
  defp calculate_percentage(yield, exit_value) do
    percentage = Decimal.div(yield, exit_value) |> Decimal.mult(Decimal.new(100))
    Decimal.round(percentage, 1) |> Decimal.to_string()
  end
end
```

Key features:
- Displays all leaderboard-eligible games
- Interactive column headers for sorting by exit value or yield
- Visual indicators for sort direction
- Shows both raw yield value and percentage of exit
- Responsive design with consistent styling
- Uses existing navbar and footer components

## 4. Navigation and Routing

We updated the router and navbar to make the leaderboard accessible throughout the application:

### 4.1 Router Update

```elixir
# lib/startup_game_web/router.ex

scope "/", StartupGameWeb do
  pipe_through [:browser]

  delete "/users/log_out", UserSessionController, :delete

  live_session :current_user,
    on_mount: [{StartupGameWeb.UserAuth, :mount_current_user}] do
    live "/users/confirm/:token", UserConfirmationLive, :edit
    live "/users/confirm", UserConfirmationInstructionsLive, :new
    live "/leaderboard", LeaderboardLive, :index
  end
end
```

This makes the leaderboard publicly accessible to both authenticated and non-authenticated users.

### 4.2 Navbar Update

We added leaderboard links to the main navigation for both desktop and mobile views:

```elixir
# Desktop Navigation (authenticated users)
<.link
  navigate={~p"/leaderboard"}
  class="text-foreground/80 hover:text-foreground transition-colors font-medium"
>
  Leaderboard
</.link>

# Desktop Navigation (non-authenticated users)
<.link
  navigate={~p"/leaderboard"}
  class="text-foreground/80 hover:text-foreground transition-colors font-medium"
>
  Leaderboard
</.link>

# Mobile Navigation (similar links with appropriate classes)
```

## 5. Testing Plan

We've created a comprehensive [test plan](leaderboard-test-plan.md) for the leaderboard functionality, covering:

1. Unit tests for the Games context functions
2. LiveView tests for the LeaderboardLive component
3. Component tests for the LeaderboardWidget
4. Integration tests to verify all parts work together correctly

These tests will ensure the leaderboard functions correctly and provides a good user experience.

## 6. Future Enhancements

Potential future enhancements for the leaderboard functionality:

1. **Pagination** - For when there are many eligible games
2. **Filtering** - Allow filtering by exit type, date range, etc.
3. **Game Details View** - Enable clicking on leaderboard entries to view more details about the game
4. **User Profiles** - Link usernames to public user profile pages
5. **Time Periods** - Allow filtering by different time periods (weekly, monthly, all-time)
6. **Achievements** - Add badges or achievements for exceptional performances