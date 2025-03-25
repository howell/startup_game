defmodule StartupGameWeb.Components.Home.HowItWorksSection do
  @moduledoc """
  How It Works section component for the home page.

  Displays the game mechanics in a grid of feature cards that explain the gameplay,
  using feature cards imported from the FeatureCard component.
  """
  use StartupGameWeb, :html
  import StartupGameWeb.Components.Home.FeatureCard, only: [feature_card: 1]

  def how_it_works_section(assigns) do
    ~H"""
    <section id="how-it-works" class="py-20 px-4">
      <div class="container mx-auto max-w-6xl">
        <div class="text-center mb-16">
          <h2 class="heading-lg mb-4">How The Game Works</h2>
          <p class="text-foreground/70 text-lg max-w-2xl mx-auto">
            Navigate the chaotic world of startups, make tough decisions, and try not to run out of money or sanity!
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <.feature_card
            icon="hero-chat-bubble-left-right"
            icon_color="text-silly-purple"
            title="Face Scenarios"
            description="Encounter absurd situations inspired by real Silicon Valley stories but with a satirical twist."
          />

          <.feature_card
            icon="hero-light-bulb"
            icon_color="text-silly-blue"
            title="Craft Responses"
            description="Write your own responses to challenges. Your choices determine your startup's fate."
          />

          <.feature_card
            icon="hero-cpu-chip"
            icon_color="text-silly-accent"
            title="Build Your Startup"
            description="Hire a quirky team, develop products, and navigate the bizarre tech ecosystem."
          />

          <.feature_card
            icon="hero-trophy"
            icon_color="text-silly-yellow"
            title="Aim for Exit"
            description="Work towards acquisition, IPO, or just try to survive longer than your competitors."
          />
        </div>
      </div>
    </section>
    """
  end
end
