defmodule StartupGameWeb.HomeLive do
  use StartupGameWeb, :live_view

  import StartupGameWeb.Components.Home.{
    HeroSection,
    HowItWorksSection,
    TestimonialsSection,
    CTASection,
    Footer
  }

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "SillyConValley.lol") |> assign(:is_home_page, true)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col mx-auto">
      <.hero_section />
      <.how_it_works_section />
      <.live_component module={StartupGameWeb.Components.Home.GamePreviewSection} id="game_preview" />
      <.testimonials_section />
      <.cta_section />
      <.footer />
    </div>
    """
  end
end
