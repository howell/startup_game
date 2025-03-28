defmodule StartupGameWeb.Components.Home.LeaderboardSection do
  @moduledoc """
  Leaderboard section component for the home page.

  Displays a compact version of the leaderboard showing the top performers,
  with a link to the full leaderboard page for more detailed information.
  """
  use StartupGameWeb, :html

  def leaderboard_section(assigns) do
    ~H"""
    <section id="leaderboard" class="py-20 px-4">
      <div class="container mx-auto max-w-6xl">
        <div class="text-center mb-16">
          <h2 class="heading-lg mb-4">Top Startup Exits</h2>
          <p class="text-foreground/70 text-lg max-w-2xl mx-auto">
            See who's crushing it in SillyConValley with the most successful exits.
            Can you make it to the top of the leaderboard?
          </p>
        </div>

        <div class="max-w-4xl mx-auto">
          <.live_component
            module={StartupGameWeb.LeaderboardWidget}
            id="home-leaderboard"
            class="mb-8"
            sort_by="exit_value"
            sort_direction={:desc}
            limit={5}
          />
        </div>
      </div>
    </section>
    """
  end
end
