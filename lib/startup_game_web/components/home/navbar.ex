defmodule StartupGameWeb.Components.Home.Navbar do
  @moduledoc """
  Navigation bar component for the entire site.

  Provides a responsive navigation bar with mobile menu toggle functionality.
  Uses JavaScript hooks for scroll detection to change styling based on scroll position.
  Works on all pages including the home page and authenticated pages.
  """
  use StartupGameWeb, :html

  attr :id, :string, required: true
  attr :current_user, :any, default: nil

  attr :is_home_page, :boolean, default: false

  def navbar(assigns) do
    ~H"""
    <header
      id={@id}
      class="fixed top-0 left-0 right-0 z-50 transition-all duration-300 py-5 bg-transparent"
      phx-hook="ScrollDetection"
    >
      <div class="container mx-auto px-4 md:px-6 flex items-center justify-between">
        <.link navigate={~p"/"} class="flex items-center gap-2">
          <span class="font-display text-2xl font-bold">
            SillyCon<span class="text-silly-accent">Valley</span>.lol
          </span>
        </.link>
        
    <!-- Desktop Navigation -->
        <nav class="hidden md:flex items-center gap-8">
          <%= if @is_home_page do %>
            <!-- Home Page Navigation -->
            <a href="#how-it-works" class={link_style()}>
              How It Works
            </a>
            <a href="#features" class={link_style()}>
              Features
            </a>
            <a href="#leaderboard" class={link_style()}>
              Leaderboard
            </a>
            <a href="#testimonials" class={link_style()}>
              Testimonials
            </a>

            <%= if @current_user do %>
              <.link navigate={~p"/games/play"} class="silly-button-primary">
                Play Now
              </.link>
            <% else %>
              <.link href={~p"/users/register"} class="silly-button-primary">
                Play Now
              </.link>
            <% end %>
          <% else %>
            <!-- Main Site Navigation -->
            <%= if @current_user do %>
              <%= if @current_user.role == :admin do %>
                <.link navigate={~p"/admin"} class={link_style()}>
                  Admin
                </.link>
              <% end %>
              <.link navigate={~p"/"} class={link_style()}>
                Home
              </.link>
              <.link navigate={~p"/games"} class={link_style()}>
                Portfolio
              </.link>
              <.link navigate={~p"/games/play"} class={link_style()}>
                New Venture
              </.link>
              <.link navigate={~p"/leaderboard"} class={link_style()}>
                Leaderboard
              </.link>
            <% else %>
              <.link navigate={~p"/"} class={link_style()}>
                Home
              </.link>
              <.link navigate={~p"/leaderboard"} class={link_style()}>
                Leaderboard
              </.link>
            <% end %>
          <% end %>
          
    <!-- User Authentication -->
          <div class="flex items-center">
            <%= if @current_user do %>
              <div class="flex items-center space-x-4">
                <span class="text-foreground/60 font-medium">
                  {@current_user.email}
                </span>
                <.link href={~p"/users/settings"} class={link_style()}>
                  Settings
                </.link>
                <.link href={~p"/users/log_out"} method="delete" class={link_style()}>
                  Log out
                </.link>
              </div>
            <% else %>
              <div class="flex items-center space-x-4">
                <.link href={~p"/users/register"} class={link_style()}>
                  Register
                </.link>
                <.link href={~p"/users/log_in"} class="silly-button-secondary">
                  Log in
                </.link>
              </div>
            <% end %>
          </div>
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
        <%= if @is_home_page do %>
          <!-- Home Page Mobile Navigation -->
          <a
            href="#how-it-works"
            class={link_style()}
            phx-click={
              JS.hide(to: "#mobile-menu")
              |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
            }
          >
            How It Works
          </a>
          <a
            href="#features"
            class={link_style() <> " p-2"}
            phx-click={
              JS.hide(to: "#mobile-menu")
              |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
            }
          >
            Features
          </a>
          <a
            href="#leaderboard"
            class={link_style() <> " p-2"}
            phx-click={
              JS.hide(to: "#mobile-menu")
              |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
            }
          >
            Leaderboard
          </a>
          <a
            href="#testimonials"
            class={link_style() <> " p-2"}
            phx-click={
              JS.hide(to: "#mobile-menu")
              |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
            }
          >
            Testimonials
          </a>

          <.link
            navigate={if @current_user, do: ~p"/games/play", else: ~p"/users/register"}
            class="silly-button-primary text-center"
            phx-click={
              JS.hide(to: "#mobile-menu")
              |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
            }
          >
            Play Now
          </.link>
        <% else %>
          <!-- Main Site Mobile Navigation -->
          <%= if @current_user do %>
            <%= if @current_user.role == :admin do %>
              <.link
                navigate={~p"/admin"}
                class={link_style() <> " p-2"}
                phx-click={
                  JS.hide(to: "#mobile-menu")
                  |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
                }
              >
                Admin
              </.link>
            <% end %>
            <.link
              navigate={~p"/"}
              class={link_style() <> " p-2"}
              phx-click={
                JS.hide(to: "#mobile-menu")
                |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
              }
            >
              Home
            </.link>
            <.link
              navigate={~p"/games"}
              class={link_style() <> " p-2"}
              phx-click={
                JS.hide(to: "#mobile-menu")
                |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
              }
            >
              Portfolio
            </.link>
            <.link
              navigate={~p"/games/play"}
              class={link_style() <> " p-2"}
              phx-click={
                JS.hide(to: "#mobile-menu")
                |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
              }
            >
              New Venture
            </.link>
            <.link
              navigate={~p"/leaderboard"}
              class={link_style() <> " p-2"}
              phx-click={
                JS.hide(to: "#mobile-menu")
                |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
              }
            >
              Leaderboard
            </.link>
          <% else %>
            <.link
              navigate={~p"/"}
              class={link_style() <> " p-2"}
              phx-click={
                JS.hide(to: "#mobile-menu")
                |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
              }
            >
              Home
            </.link>
            <.link
              navigate={~p"/leaderboard"}
              class={link_style() <> " p-2"}
              phx-click={
                JS.hide(to: "#mobile-menu")
                |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
              }
            >
              Leaderboard
            </.link>
          <% end %>
        <% end %>
        
    <!-- Mobile User Authentication -->
        <%= if @current_user do %>
          <div class="border-t border-gray-100 mt-2 pt-2">
            <div class="text-foreground/80 font-medium p-2 block">
              {@current_user.email}
            </div>
            <.link
              href={~p"/users/settings"}
              class={link_style() <> "p-2 block"}
              phx-click={
                JS.hide(to: "#mobile-menu")
                |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
              }
            >
              Settings
            </.link>
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class={link_style() <> "p-2 block"}
              phx-click={
                JS.hide(to: "#mobile-menu")
                |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
              }
            >
              Log out
            </.link>
          </div>
        <% else %>
          <div class="border-t border-gray-100 mt-2 pt-2">
            <.link
              href={~p"/users/register"}
              class={link_style() <> "p-2 block"}
              phx-click={
                JS.hide(to: "#mobile-menu")
                |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
              }
            >
              Register
            </.link>
            <.link
              href={~p"/users/log_in"}
              class={link_style() <> "p-2 block"}
              phx-click={
                JS.hide(to: "#mobile-menu")
                |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
              }
            >
              Log in
            </.link>
          </div>
        <% end %>
      </div>
    </header>
    """
  end

  defp link_style, do: "text-foreground/80 hover:text-foreground transition-colors font-medium"
end
