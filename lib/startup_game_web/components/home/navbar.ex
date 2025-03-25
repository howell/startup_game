defmodule StartupGameWeb.Components.Home.Navbar do
  @moduledoc """
  Navigation bar component for the home page.

  Provides a responsive navigation bar with mobile menu toggle functionality.
  Uses JavaScript hooks for scroll detection to change styling based on scroll position.
  """
  use StartupGameWeb, :html

  attr :id, :string, required: true

  def navbar(assigns) do
    ~H"""
    <header
      id={@id}
      class="fixed top-0 left-0 right-0 z-50 transition-all duration-300 py-5 bg-transparent"
      phx-hook="ScrollDetection"
    >
      <div class="container mx-auto px-4 md:px-6 flex items-center justify-between">
        <a href="#" class="flex items-center gap-2">
          <span class="font-display text-2xl font-bold">
            SillyCon<span class="text-silly-accent">Valley</span>.lol
          </span>
        </a>

    <!-- Desktop Navigation -->
        <nav class="hidden md:flex items-center gap-8">
          <a
            href="#how-it-works"
            class="text-foreground/80 hover:text-foreground transition-colors font-medium"
          >
            How It Works
          </a>
          <a
            href="#features"
            class="text-foreground/80 hover:text-foreground transition-colors font-medium"
          >
            Features
          </a>
          <a
            href="#testimonials"
            class="text-foreground/80 hover:text-foreground transition-colors font-medium"
          >
            Testimonials
          </a>
          <a href="#play-now" class="silly-button-primary">
            Play Now
          </a>
        </nav>

    <!-- Mobile Navigation Toggle -->
        <button
          class="md:hidden silly-button-secondary !p-2"
          phx-click={
            JS.toggle(to: "#mobile-menu") |> JS.dispatch("toggle-aria-expanded", to: "##{@id}")
          }
          aria-label="Toggle Menu"
          aria-expanded="false"
        >
          <.icon name="hero-bars-3" class="h-6 w-6 block" id="menu-open-icon" />
          <.icon name="hero-x-mark" class="h-6 w-6 hidden" id="menu-close-icon" />
        </button>
      </div>

    <!-- Mobile Navigation Menu -->
      <div
        id="mobile-menu"
        class="md:hidden hidden absolute top-full left-0 right-0 bg-white shadow-lg p-4 flex flex-col gap-4 animate-fade-in"
      >
        <a
          href="#how-it-works"
          class="text-foreground/80 hover:text-foreground transition-colors font-medium p-2"
          phx-click={
            JS.hide(to: "#mobile-menu") |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
          }
        >
          How It Works
        </a>
        <a
          href="#features"
          class="text-foreground/80 hover:text-foreground transition-colors font-medium p-2"
          phx-click={
            JS.hide(to: "#mobile-menu") |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
          }
        >
          Features
        </a>
        <a
          href="#testimonials"
          class="text-foreground/80 hover:text-foreground transition-colors font-medium p-2"
          phx-click={
            JS.hide(to: "#mobile-menu") |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
          }
        >
          Testimonials
        </a>
        <a
          href="#play-now"
          class="silly-button-primary text-center"
          phx-click={
            JS.hide(to: "#mobile-menu") |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
          }
        >
          Play Now
        </a>
      </div>
    </header>
    """
  end
end
