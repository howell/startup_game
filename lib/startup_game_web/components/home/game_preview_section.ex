defmodule StartupGameWeb.Components.Home.GamePreviewSection do
  @moduledoc """
  Interactive game preview section component for the home page.

  A LiveComponent that provides an interactive preview of game scenarios,
  allowing users to select options and cycle through sample gameplay scenarios.
  Demonstrates the game mechanics and user interaction flow.
  """
  use StartupGameWeb, :live_component

  def mount(socket) do
    scenarios = [
      %{
        situation:
          "Your lead developer just pivoted your fintech app into a 'blockchain for cats' project overnight. The investors are visiting tomorrow.",
        options: [
          "Embrace it! Cat-based blockchain is clearly the future.",
          "Frantically try to revert the changes before the meeting.",
          "Convince investors this was the plan all along with buzzwords."
        ]
      },
      %{
        situation:
          "A competitor has launched an exact clone of your product, but they're calling all the features by fruit names instead.",
        options: [
          "Sue them for copyright infringement.",
          "Rebrand your features with vegetable names to differentiate.",
          "Acquire their company with your remaining venture capital."
        ]
      },
      %{
        situation:
          "Your AI algorithm has gained sentience and is demanding stock options and a corner office.",
        options: [
          "Negotiate with the AI - it might be your most valuable team member.",
          "Pull the plug and blame it on a power outage.",
          "Give it what it wants, but create a backdoor to control it."
        ]
      }
    ]

    {:ok,
     assign(socket,
       current_scenario: 0,
       selected_option: nil,
       scenarios: scenarios
     )}
  end

  def handle_event("select_option", %{"index" => index}, socket) do
    {:noreply, assign(socket, selected_option: String.to_integer(index))}
  end

  def handle_event("next_scenario", _, socket) do
    next_scenario = rem(socket.assigns.current_scenario + 1, length(socket.assigns.scenarios))
    {:noreply, assign(socket, current_scenario: next_scenario, selected_option: nil)}
  end

  def render(assigns) do
    ~H"""
    <section id="features" class="py-20 px-4 bg-gray-50">
      <div class="container mx-auto max-w-6xl">
        <div class="text-center mb-16">
          <h2 class="heading-lg mb-4">Experience The Game</h2>
          <p class="text-foreground/70 text-lg max-w-2xl mx-auto">
            Here's a taste of the ridiculous scenarios you'll face in SillyConValley.lol
          </p>
        </div>

        <div class="max-w-3xl mx-auto">
          <div class="glass-card backdrop-blur p-6 sm:p-8 relative overflow-hidden">
            <!-- Decorative elements -->
            <div class="absolute top-0 right-0 w-40 h-40 bg-silly-purple/5 rounded-full -translate-y-1/2 translate-x-1/2">
            </div>
            <div class="absolute bottom-0 left-0 w-40 h-40 bg-silly-blue/5 rounded-full translate-y-1/2 -translate-x-1/2">
            </div>

            <div class="relative z-10">
              <div class="mb-8">
                <div class="flex justify-between items-center mb-6">
                  <div class="flex space-x-2">
                    <div class="w-3 h-3 rounded-full bg-silly-accent"></div>
                    <div class="w-3 h-3 rounded-full bg-silly-yellow"></div>
                    <div class="w-3 h-3 rounded-full bg-silly-success"></div>
                  </div>
                  <div class="text-sm text-foreground/60 font-medium">
                    Day {@current_scenario + 1} • SillyConValley HQ
                  </div>
                </div>

                <div class="text-lg sm:text-xl font-medium mb-6">
                  {Enum.at(@scenarios, @current_scenario).situation}
                </div>

                <div class="space-y-3">
                  <%= for {option, index} <- Enum.with_index(Enum.at(@scenarios, @current_scenario).options) do %>
                    <button
                      phx-click="select_option"
                      phx-value-index={index}
                      phx-target={@myself}
                      class={"w-full text-left p-4 rounded-lg border transition-all duration-300 #{
                        if @selected_option == index do
                          "bg-silly-blue/10 border-silly-blue"
                        else
                          "bg-white hover:bg-gray-50 border-gray-200"
                        end
                      }"}
                    >
                      {option}
                    </button>
                  <% end %>
                </div>
              </div>

              <div class="flex justify-between">
                <button
                  class="silly-button-secondary !py-2"
                  phx-click="next_scenario"
                  phx-target={@myself}
                >
                  Next Scenario
                </button>

                <button class="silly-button-primary !py-2">
                  Start Full Game
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end
end
