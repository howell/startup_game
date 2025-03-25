defmodule StartupGameWeb.Components.Home.CTASection do
  @moduledoc """
  Call to Action (CTA) section component for the home page.

  Displays a prominent section with a rocket icon, heading, description,
  and action buttons to encourage users to start playing the game.
  Includes decorative background elements for visual appeal.
  """
  use StartupGameWeb, :html

  def cta_section(assigns) do
    ~H"""
    <section id="play-now" class="py-20 px-4 bg-gradient-to-b from-white to-gray-50">
      <div class="container mx-auto max-w-6xl">
        <div class="bg-white rounded-3xl shadow-xl overflow-hidden">
          <div class="relative p-8 sm:p-12 text-center">
            <!-- Background decorative elements -->
            <div class="absolute top-0 right-0 w-64 h-64 bg-silly-purple/5 rounded-full -translate-y-1/3 translate-x-1/3">
            </div>
            <div class="absolute bottom-0 left-0 w-64 h-64 bg-silly-blue/5 rounded-full translate-y-1/3 -translate-x-1/3">
            </div>

            <div class="relative z-10 max-w-3xl mx-auto">
              <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-silly-blue/10 mb-6">
                <.icon name="hero-rocket" class="text-silly-blue" />
              </div>

              <h2 class="heading-lg mb-4">Start Your Startup Adventure</h2>
              <p class="text-foreground/70 text-lg mb-8 max-w-2xl mx-auto">
                Ready to build a company, navigate absurd challenges, and experience the roller coaster of startup life? Jump into SillyConValley.lol now!
              </p>

              <div class="flex flex-col sm:flex-row gap-4 justify-center">
                <a href="#" class="silly-button-primary text-center">
                  Play Now
                </a>
                <a href="#" class="silly-button-secondary text-center">
                  Learn More
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end
end
