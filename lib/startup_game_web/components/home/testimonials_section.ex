defmodule StartupGameWeb.Components.Home.TestimonialsSection do
  @moduledoc """
  Testimonials section component for the home page.

  Displays customer testimonials in a responsive grid layout with styled quote cards.
  """
  use StartupGameWeb, :html

  def testimonials_section(assigns) do
    ~H"""
    <section id="testimonials" class="py-20 px-4 bg-gray-50">
      <div class="container mx-auto max-w-6xl">
        <div class="text-center mb-16">
          <h2 class="heading-lg mb-4">What Players Say</h2>
          <p class="text-foreground/70 text-lg max-w-2xl mx-auto">
            Hear from those who survived (or hilariously failed) in SillyConValley
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <.testimonial
            content="My virtual startup pivoted 7 times and ended up making AI-powered toasters for pets. Still better than my real startup experience!"
            author="Sarah Johnson"
            role="Ex-Founder, Now Happy Baker"
            class="lg:transform lg:-rotate-1"
          />

          <.testimonial
            content="I burned through $10M virtual VC funding in two game days. My investors said it was the most realistic simulator they've ever seen."
            author="Michael Chen"
            role="Serial Entrepreneur"
            class="lg:transform lg:rotate-1 lg:translate-y-4"
          />

          <.testimonial
            content="My startup got acquired for $2B by a company that doesn't exist. Just like in real Silicon Valley!"
            author="Alex Rodriguez"
            role="Product Manager"
            class="lg:transform lg:-rotate-1 lg:translate-y-2"
          />
        </div>
      </div>
    </section>
    """
  end

  attr :content, :string, required: true
  attr :author, :string, required: true
  attr :role, :string, required: true
  attr :class, :string, default: ""

  def testimonial(assigns) do
    ~H"""
    <div class={"p-6 bg-white rounded-2xl shadow-lg border border-gray-100 #{@class}"}>
      <p class="text-foreground/80 mb-6 italic">{@content}</p>
      <div>
        <div class="font-medium">{@author}</div>
        <div class="text-sm text-foreground/60">{@role}</div>
      </div>
    </div>
    """
  end
end
