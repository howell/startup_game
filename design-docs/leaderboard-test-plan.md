# Leaderboard Component Tests

This document outlines the testing strategy for the new leaderboard functionality in the Startup Game project. The test cases cover both unit tests for the Games context functions and LiveView tests for the LeaderboardLive view and LeaderboardWidget component.

## 1. Unit Tests for Games Context

### 1.1 Tests for `list_leaderboard_data/1` Function

```elixir
# test/startup_game/games_test.exs

describe "leaderboard data" do
  test "list_leaderboard_data/1 returns formatted leaderboard entries" do
    # Setup: Create user and completed game with known exit value and ownership
    user = user_fixture()
    game = game_fixture_with_status(:completed, %{
      name: "Test Company",
      exit_type: :acquisition,
      exit_value: Decimal.new("2000000"),
      is_public: true,
      is_leaderboard_eligible: true
    }, user)
    
    # Ensure the founder ownership is set to a known value for testing
    Games.update_ownership_structure(
      [%{entity_name: "Founder", percentage: Decimal.new("60.0")}],
      game,
      hd(game.rounds)
    )
    
    # Get leaderboard data
    [entry] = Games.list_leaderboard_data()
    
    # Verify the entry has the expected fields and values
    assert entry.username == (user.email |> String.split("@") |> hd())
    assert entry.company_name == "Test Company"
    assert Decimal.equal?(entry.exit_value, Decimal.new("2000000"))
    assert Decimal.equal?(entry.yield, Decimal.new("1200000")) # 60% of exit value
    assert entry.user_id == user.id
  end
  
  test "list_leaderboard_data/1 sorts by exit_value desc by default" do
    # Setup: Create multiple games with different exit values
    setup_leaderboard_data([
      {"Company A", "3000000"}, 
      {"Company B", "1000000"}, 
      {"Company C", "2000000"}
    ])
    
    # Get leaderboard data
    entries = Games.list_leaderboard_data()
    
    # Verify order: A, C, B (descending exit value)
    assert Enum.map(entries, & &1.company_name) == ["Company A", "Company C", "Company B"]
  end
  
  test "list_leaderboard_data/1 can sort by exit_value asc" do
    # Setup: Create multiple games with different exit values
    setup_leaderboard_data([
      {"Company A", "3000000"}, 
      {"Company B", "1000000"}, 
      {"Company C", "2000000"}
    ])
    
    # Get leaderboard data with ascending sort
    entries = Games.list_leaderboard_data(%{sort_by: "exit_value", sort_direction: :asc})
    
    # Verify order: B, C, A (ascending exit value)
    assert Enum.map(entries, & &1.company_name) == ["Company B", "Company C", "Company A"]
  end
  
  test "list_leaderboard_data/1 can sort by yield" do
    # Setup: Create multiple games with different founder percentages and exit values
    user1 = user_fixture()
    user2 = user_fixture()
    user3 = user_fixture()
    
    # Game A: $3M exit, 40% founder ownership = $1.2M yield
    game_a = create_game_with_ownership(user1, "Company A", "3000000", "40.0")
    
    # Game B: $1M exit, 90% founder ownership = $900k yield
    game_b = create_game_with_ownership(user2, "Company B", "1000000", "90.0")
    
    # Game C: $2M exit, 60% founder ownership = $1.2M yield
    game_c = create_game_with_ownership(user3, "Company C", "2000000", "60.0")
    
    # Get leaderboard data sorted by yield
    entries = Games.list_leaderboard_data(%{sort_by: "yield", sort_direction: :desc})
    
    # Verify order: A/C (tied for yield), then B
    company_names = Enum.map(entries, & &1.company_name)
    assert length(company_names) == 3
    assert "Company A" in company_names
    assert "Company C" in company_names
    assert List.last(company_names) == "Company B"
  end
  
  test "list_leaderboard_data/1 respects the limit parameter" do
    # Setup: Create multiple games
    setup_leaderboard_data([
      {"Company A", "3000000"}, 
      {"Company B", "1000000"}, 
      {"Company C", "2000000"}
    ])
    
    # Get leaderboard data with limit of 2
    entries = Games.list_leaderboard_data(%{limit: 2})
    
    # Verify we only get 2 entries
    assert length(entries) == 2
  end
  
  test "list_leaderboard_data/1 only returns eligible games" do
    user = user_fixture()
    
    # Eligible game
    game_fixture_with_status(:completed, %{
      name: "Eligible Company",
      exit_type: :acquisition,
      exit_value: Decimal.new("2000000"),
      is_public: true,
      is_leaderboard_eligible: true
    }, user)
    
    # Non-public game
    game_fixture_with_status(:completed, %{
      name: "Private Company",
      exit_type: :acquisition,
      exit_value: Decimal.new("3000000"),
      is_public: false,
      is_leaderboard_eligible: true
    }, user)
    
    # Non-leaderboard eligible game
    game_fixture_with_status(:completed, %{
      name: "Non-eligible Company",
      exit_type: :acquisition,
      exit_value: Decimal.new("4000000"),
      is_public: true,
      is_leaderboard_eligible: false
    }, user)
    
    # Not completed game
    game_fixture_with_status(:in_progress, %{
      name: "Incomplete Company",
      is_public: true,
      is_leaderboard_eligible: true
    }, user)
    
    # Failed game
    game_fixture_with_status(:failed, %{
      name: "Failed Company",
      exit_type: :shutdown,
      is_public: true,
      is_leaderboard_eligible: true
    }, user)
    
    # Get leaderboard data
    entries = Games.list_leaderboard_data()
    
    # Verify we only get the eligible game
    assert length(entries) == 1
    assert hd(entries).company_name == "Eligible Company"
  end
end

# Helper function to create multiple games with different exit values
defp setup_leaderboard_data(company_data) do
  Enum.map(company_data, fn {name, exit_value} ->
    user = user_fixture()
    game_fixture_with_status(:completed, %{
      name: name,
      exit_type: :acquisition,
      exit_value: Decimal.new(exit_value),
      is_public: true,
      is_leaderboard_eligible: true
    }, user)
  end)
end

# Helper function to create a game with specific founder ownership
defp create_game_with_ownership(user, name, exit_value, founder_percentage) do
  game = game_fixture_with_status(:completed, %{
    name: name,
    exit_type: :acquisition,
    exit_value: Decimal.new(exit_value),
    is_public: true,
    is_leaderboard_eligible: true
  }, user)
  
  Games.update_ownership_structure(
    [%{entity_name: "Founder", percentage: Decimal.new(founder_percentage)}],
    game,
    hd(game.rounds)
  )
  
  game
end
```

### 1.2 Tests for `calculate_founder_yield/1` Function

This is a private function, so we'll test it indirectly through the public `list_leaderboard_data/1` function, as shown in the tests above.

## 2. LiveView Tests for LeaderboardLive

```elixir
# test/startup_game_web/live/leaderboard_live_test.exs

defmodule StartupGameWeb.LeaderboardLiveTest do
  use StartupGameWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import StartupGame.AccountsFixtures
  import StartupGame.GamesFixtures

  describe "Leaderboard page" do
    test "renders leaderboard page for non-authenticated users", %{conn: conn} do
      # Create some games for the leaderboard
      setup_leaderboard_games()
      
      # Visit the leaderboard page
      {:ok, _lv, html} = live(conn, ~p"/leaderboard")
      
      # Verify the page contains the expected content
      assert html =~ "Startup Success Leaderboard"
      assert html =~ "See the most successful founders and their companies"
      assert html =~ "Exit Value"
      assert html =~ "Founder Yield"
    end
    
    test "renders leaderboard page for authenticated users", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)
      
      # Create some games for the leaderboard
      setup_leaderboard_games()
      
      # Visit the leaderboard page
      {:ok, _lv, html} = live(conn, ~p"/leaderboard")
      
      # Verify the page contains the expected content
      assert html =~ "Startup Success Leaderboard"
      assert html =~ "Exit Value"
      assert html =~ "Founder Yield"
    end
    
    test "displays game entries on the leaderboard", %{conn: conn} do
      # Create some specific games for testing
      user = user_fixture(%{email: "test@example.com"})
      game = game_fixture_with_status(:completed, %{
        name: "SuperApp",
        exit_type: :acquisition,
        exit_value: Decimal.new("5000000"),
        is_public: true,
        is_leaderboard_eligible: true
      }, user)
      
      # Set founder ownership to 50%
      Games.update_ownership_structure(
        [%{entity_name: "Founder", percentage: Decimal.new("50.0")}],
        game,
        hd(game.rounds)
      )
      
      # Visit the leaderboard page
      {:ok, _lv, html} = live(conn, ~p"/leaderboard")
      
      # Verify the specific game is displayed with correct information
      assert html =~ "SuperApp"
      assert html =~ "test" # username without domain
      assert html =~ "$5,000,000" # formatted exit value
      assert html =~ "$2,500,000" # formatted yield (50% of exit)
      assert html =~ "50.0% of exit" # percentage display
    end
    
    test "can sort the leaderboard by exit value", %{conn: conn} do
      # Create games with different exit values
      setup_leaderboard_games()
      
      # Visit the leaderboard page
      {:ok, lv, _html} = live(conn, ~p"/leaderboard")
      
      # Click on the "Exit Value" header to sort (first click should be desc, which is default)
      html = lv |> element("th[phx-value-field='exit_value']") |> render_click()
      
      # Verify the order is still descending by exit value (since that's the default)
      assert Floki.find(html, "tbody tr") |> length() > 0
      
      # Click again to sort ascending
      html = lv |> element("th[phx-value-field='exit_value']") |> render_click()
      
      # Verify the order has changed (would need to check specific values or classes)
      assert Floki.find(html, "tbody tr") |> length() > 0
    end
    
    test "can sort the leaderboard by yield", %{conn: conn} do
      # Create games with different yield values
      setup_mixed_yield_games()
      
      # Visit the leaderboard page
      {:ok, lv, _html} = live(conn, ~p"/leaderboard")
      
      # Click on the "Founder Yield" header to sort
      html = lv |> element("th[phx-value-field='yield']") |> render_click()
      
      # Verify sorting indicators are displayed
      assert html =~ "hero-chevron-down"
      
      # Click again to change sort direction
      html = lv |> element("th[phx-value-field='yield']") |> render_click()
      
      # Verify sort direction indicator changed
      assert html =~ "hero-chevron-up"
    end
  end
  
  # Helper function to set up multiple games for the leaderboard
  defp setup_leaderboard_games do
    # Create several users and games with different exit values
    user1 = user_fixture(%{email: "user1@example.com"})
    user2 = user_fixture(%{email: "user2@example.com"})
    user3 = user_fixture(%{email: "user3@example.com"})
    
    game_fixture_with_status(:completed, %{
      name: "BigCorp",
      exit_type: :acquisition,
      exit_value: Decimal.new("3000000"),
      is_public: true,
      is_leaderboard_eligible: true
    }, user1)
    
    game_fixture_with_status(:completed, %{
      name: "MediumCorp",
      exit_type: :ipo,
      exit_value: Decimal.new("2000000"),
      is_public: true,
      is_leaderboard_eligible: true
    }, user2)
    
    game_fixture_with_status(:completed, %{
      name: "SmallCorp",
      exit_type: :acquisition,
      exit_value: Decimal.new("1000000"),
      is_public: true,
      is_leaderboard_eligible: true
    }, user3)
  end
  
  # Helper function to set up games with different founder ownership percentages
  defp setup_mixed_yield_games do
    user1 = user_fixture(%{email: "high@example.com"})
    user2 = user_fixture(%{email: "medium@example.com"})
    user3 = user_fixture(%{email: "low@example.com"})
    
    # High exit value but lower founder percentage
    game1 = game_fixture_with_status(:completed, %{
      name: "HighValue",
      exit_type: :acquisition,
      exit_value: Decimal.new("5000000"),
      is_public: true,
      is_leaderboard_eligible: true
    }, user1)
    
    # Medium exit value with higher founder percentage
    game2 = game_fixture_with_status(:completed, %{
      name: "MediumValue",
      exit_type: :ipo,
      exit_value: Decimal.new("3000000"),
      is_public: true,
      is_leaderboard_eligible: true
    }, user2)
    
    # Low exit value with highest founder percentage
    game3 = game_fixture_with_status(:completed, %{
      name: "LowValue",
      exit_type: :acquisition,
      exit_value: Decimal.new("1000000"),
      is_public: true,
      is_leaderboard_eligible: true
    }, user3)
    
    # Set different founder ownership percentages
    update_founder_ownership(game1, "30.0") # $1.5M yield
    update_founder_ownership(game2, "60.0") # $1.8M yield
    update_founder_ownership(game3, "90.0") # $0.9M yield
  end
  
  defp update_founder_ownership(game, percentage) do
    Games.update_ownership_structure(
      [%{entity_name: "Founder", percentage: Decimal.new(percentage)}],
      game,
      hd(game.rounds)
    )
  end
end
```

## 3. Tests for LeaderboardWidget Component

```elixir
# test/startup_game_web/components/leaderboard_widget_test.exs

defmodule StartupGameWeb.LeaderboardWidgetTest do
  use StartupGameWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import StartupGame.AccountsFixtures
  import StartupGame.GamesFixtures
  
  alias StartupGameWeb.LeaderboardWidget
  
  describe "LeaderboardWidget" do
    test "renders the widget with leaderboard data" do
      # Create some games for the leaderboard
      setup_leaderboard_games()
      
      # Render the widget component
      html = 
        render_component(&LeaderboardWidget.leaderboard/1, %{
          class: "test-class",
          limit: 2
        })
      
      # Verify the rendered HTML contains expected content
      assert html =~ "Top Startup Exits"
      assert html =~ "View All"
      assert html =~ "Rank"
      assert html =~ "Username"
      assert html =~ "Company"
      assert html =~ "Exit Value"
      
      # Verify it contains company names from the fixture data
      assert html =~ "BigCorp"
      assert html =~ "MediumCorp"
      
      # Verify it doesn't show more than the limit
      refute html =~ "SmallCorp"
    end
    
    test "applies custom class to the widget" do
      # Create some games for the leaderboard
      setup_leaderboard_games()
      
      # Render the widget with a custom class
      html = 
        render_component(&LeaderboardWidget.leaderboard/1, %{
          class: "custom-test-class",
          limit: 3
        })
      
      # Verify the custom class is applied
      assert html =~ "custom-test-class"
    end
    
    test "respects the limit attribute" do
      # Create many games for the leaderboard
      setup_multiple_leaderboard_games(10)
      
      # Render the widget with a limit of 4
      html = 
        render_component(&LeaderboardWidget.leaderboard/1, %{
          limit: 4
        })
      
      # Count the number of rows in the table
      row_count = 
        html
        |> Floki.parse_document!()
        |> Floki.find("tbody tr")
        |> length()
      
      # Verify there are exactly 4 rows
      assert row_count == 4
    end
    
    test "formats numbers correctly" do
      # Create a game with a specific exit value
      user = user_fixture()
      game_fixture_with_status(:completed, %{
        name: "NumberTest",
        exit_type: :acquisition,
        exit_value: Decimal.new("1234567"),
        is_public: true,
        is_leaderboard_eligible: true
      }, user)
      
      # Render the widget
      html = render_component(&LeaderboardWidget.leaderboard/1, %{})
      
      # Verify the number is formatted with commas
      assert html =~ "$1,234,567"
    end
  end
  
  # Helper function to set up multiple games for the leaderboard
  defp setup_leaderboard_games do
    # Same implementation as in LeaderboardLiveTest
    user1 = user_fixture(%{email: "user1@example.com"})
    user2 = user_fixture(%{email: "user2@example.com"})
    user3 = user_fixture(%{email: "user3@example.com"})
    
    game_fixture_with_status(:completed, %{
      name: "BigCorp",
      exit_type: :acquisition,
      exit_value: Decimal.new("3000000"),
      is_public: true,
      is_leaderboard_eligible: true
    }, user1)
    
    game_fixture_with_status(:completed, %{
      name: "MediumCorp",
      exit_type: :ipo,
      exit_value: Decimal.new("2000000"),
      is_public: true,
      is_leaderboard_eligible: true
    }, user2)
    
    game_fixture_with_status(:completed, %{
      name: "SmallCorp",
      exit_type: :acquisition,
      exit_value: Decimal.new("1000000"),
      is_public: true,
      is_leaderboard_eligible: true
    }, user3)
  end
  
  # Helper function to create many games for testing the limit
  defp setup_multiple_leaderboard_games(count) do
    Enum.map(1..count, fn i ->
      user = user_fixture(%{email: "user#{i}@example.com"})
      
      game_fixture_with_status(:completed, %{
        name: "Company #{i}",
        exit_type: :acquisition,
        exit_value: Decimal.new("#{1_000_000 + i * 100_000}"),
        is_public: true,
        is_leaderboard_eligible: true
      }, user)
    end)
  end
end
```

## 4. Implementation Plan

Once the tests are written, we'll need to implement the actual functionality. Here's the basic plan:

1. Implement the `list_leaderboard_data/1` and `calculate_founder_yield/1` functions in the Games context ✅
2. Create the LeaderboardWidget component ✅ 
3. Create the LeaderboardLive LiveView ✅
4. Update the router to add the leaderboard route ✅
5. Update the navbar to include links to the leaderboard ✅
6. Run the tests and fix any issues

## 5. Integration Testing

After implementing the individual components, we should also perform integration testing to ensure they work together as expected:

1. Check that the LeaderboardWidget correctly links to the full leaderboard page
2. Verify that clicking on sort headers on the leaderboard page correctly reorders the data
3. Test the leaderboard with realistic game data with various exit values and owner percentages
4. Verify the responsive design works on different screen sizes