defmodule StartupGameWeb.Components.Home.HeroSection do
  @moduledoc """
  Hero section component for the home page.

  Displays the main marketing message with animated background elements,
  call-to-action buttons, and a scroll indicator.
  """
  use StartupGameWeb, :html

  def hero_section(assigns) do
    ~H"""
    <section class="relative min-h-screen overflow-hidden flex flex-col items-center justify-center pt-20 pb-10 px-4">
      <!-- Background Decorations -->
      <div class="absolute inset-0 overflow-hidden -z-10">
        <div class="absolute top-20 left-[10%] w-72 h-72 bg-silly-purple/20 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob">
        </div>
        <div class="absolute top-40 right-[10%] w-72 h-72 bg-silly-yellow/20 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-2000">
        </div>
        <div class="absolute -bottom-8 left-[20%] w-72 h-72 bg-silly-blue/20 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-4000">
        </div>
      </div>

      <div class="container mx-auto max-w-6xl">
        <div class="text-center space-y-6 animate-fade-in">
          <div class="inline-block mb-4">
            <span class="px-3 py-1 rounded-full text-sm font-medium bg-silly-purple/10 text-silly-purple">
              Text-based Startup Adventure Game
            </span>
          </div>

          <h1 class="heading-xl max-w-4xl mx-auto">
            Build Your Startup &
            <span class="text-gradient bg-gradient-to-r from-silly-purple to-silly-blue ml-2">
              Face The Absurdity
            </span>
          </h1>

          <p class="text-foreground/70 text-lg md:text-xl max-w-2xl mx-auto">
            Navigate ridiculous scenarios, make tough decisions, and try not to burn through your VC money too fast. It's just like real Silicon Valley, but funnier!
          </p>

          <div class="flex flex-col sm:flex-row gap-4 justify-center pt-6">
            <.link navigate={~p"/games/play"} class="silly-button-primary text-center">
              Start Your Startup Journey
            </.link>
            <a href="#how-it-works" class="silly-button-secondary text-center">
              How It Works
            </a>
          </div>
        </div>
      </div>
    </section>
    """
  end
end
