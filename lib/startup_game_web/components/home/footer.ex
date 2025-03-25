defmodule StartupGameWeb.Components.Home.Footer do
  @moduledoc """
  Footer component for the home page.

  Provides site navigation, copyright information, and social media links
  in a responsive multi-column layout.
  """
  use StartupGameWeb, :html

  def footer(assigns) do
    ~H"""
    <footer class="bg-white py-12 px-4 border-t border-gray-100">
      <div class="container mx-auto max-w-6xl">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div class="col-span-1 md:col-span-2">
            <a href="#" class="inline-block mb-4">
              <span class="font-display text-2xl font-bold">
                SillyCon<span class="text-silly-accent">Valley</span>.lol
              </span>
            </a>
            <p class="text-foreground/60 max-w-md">
              A satirical text-based adventure game where you build a startup, face absurd challenges, and try not to burn all your VC money.
            </p>
          </div>

          <div>
            <h3 class="font-bold mb-4">Game</h3>
            <ul class="space-y-2">
              <li><a href="#" class="text-foreground/60 hover:text-foreground">How to Play</a></li>
              <li><a href="#" class="text-foreground/60 hover:text-foreground">Features</a></li>
              <li><a href="#" class="text-foreground/60 hover:text-foreground">Updates</a></li>
              <li><a href="#" class="text-foreground/60 hover:text-foreground">Community</a></li>
            </ul>
          </div>

          <div>
            <h3 class="font-bold mb-4">Company</h3>
            <ul class="space-y-2">
              <li><a href="#" class="text-foreground/60 hover:text-foreground">About Us</a></li>
              <li><a href="#" class="text-foreground/60 hover:text-foreground">Contact</a></li>
              <li><a href="#" class="text-foreground/60 hover:text-foreground">Privacy</a></li>
              <li><a href="#" class="text-foreground/60 hover:text-foreground">Terms</a></li>
            </ul>
          </div>
        </div>

        <div class="border-t border-gray-100 mt-12 pt-8 flex flex-col md:flex-row justify-between items-center">
          <p class="text-foreground/60 text-sm mb-4 md:mb-0">
            &copy; {DateTime.utc_now().year} SillyConValley.lol • All rights reserved
          </p>

          <div class="flex space-x-4">
            <a href="#" class="text-foreground/60 hover:text-foreground transition-colors">
              Twitter
            </a>
            <a href="#" class="text-foreground/60 hover:text-foreground transition-colors">
              Facebook
            </a>
            <a href="#" class="text-foreground/60 hover:text-foreground transition-colors">
              Instagram
            </a>
          </div>
        </div>
      </div>
    </footer>
    """
  end
end
