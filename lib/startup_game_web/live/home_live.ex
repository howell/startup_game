defmodule StartupGameWeb.HomeLive do
  use StartupGameWeb, :live_view

  import StartupGameWeb.Components.Home.{
    HeroSection,
    HowItWorksSection,
    TestimonialsSection,
    CTASection,
    Footer,
    Navbar
  }

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col">
      <.navbar id="main-navbar" />
      <main>
        <.hero_section />
        <.how_it_works_section />
        <.live_component module={StartupGameWeb.Components.Home.GamePreviewSection} id="game_preview" />
        <.testimonials_section />
        <.cta_section />
      </main>
      <.footer />
    </div>
    """
  end
end
