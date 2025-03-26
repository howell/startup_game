defmodule StartupGameWeb.LeaderboardLive do
  use StartupGameWeb, :live_view
  alias StartupGame.Games
  import StartupGameWeb.Components.Home.Navbar
  import StartupGameWeb.Components.Home.Footer

  def mount(_params, _session, socket) do
    # Fetch real leaderboard data
    leaderboard_data = Games.list_leaderboard_data(%{sort_by: "exit_value"})

    {:ok,
     assign(socket,
       page_title: "Leaderboard",
       leaderboard_data: leaderboard_data,
       # Default sort
       sort_by: "exit_value",
       sort_direction: :desc
     )}
  end

  def handle_event("sort", %{"field" => field}, socket) do
    current_field = socket.assigns.sort_by
    current_direction = socket.assigns.sort_direction

    # If clicking the same field, toggle direction; otherwise, use desc
    {new_field, new_direction} =
      if field == current_field do
        {field, if(current_direction == :desc, do: :asc, else: :desc)}
      else
        {field, :desc}
      end

    # Get fresh data with new sort
    sorted_data =
      Games.list_leaderboard_data(%{
        sort_by: new_field,
        sort_direction: new_direction
      })

    {:noreply,
     assign(socket,
       leaderboard_data: sorted_data,
       sort_by: new_field,
       sort_direction: new_direction
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <.navbar id="leaderboard-navbar" current_user={@current_user} />

      <main class="pt-20 pb-10">
        <div class="container mx-auto px-4">
          <div class="flex flex-col items-center mb-8">
            <h1 class="text-3xl font-bold text-gray-900 mb-2">Startup Success Leaderboard</h1>
            <p class="text-gray-600 text-center max-w-2xl">
              See the most successful founders and their companies in SillyConValley.
              Sort by either exit value or founder yield to discover different success stories.
            </p>
          </div>

          <div class="bg-white rounded-xl shadow-md overflow-hidden">
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-100">
                  <tr>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Rank
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Username
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Company
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer group"
                      phx-click="sort"
                      phx-value-field="exit_value"
                    >
                      <div class="flex items-center">
                        Exit Value
                        <span class={"ml-1 text-silly-blue transition-all duration-200 #{if @sort_by == "exit_value", do: "opacity-100", else: "opacity-0 group-hover:opacity-50"}"}>
                          <%= cond do %>
                            <% @sort_by == "exit_value" && @sort_direction == :desc -> %>
                              <.icon name="hero-chevron-down" class="h-4 w-4" />
                            <% @sort_by == "exit_value" && @sort_direction == :asc -> %>
                              <.icon name="hero-chevron-up" class="h-4 w-4" />
                            <% true -> %>
                              <.icon name="hero-chevron-down" class="h-4 w-4" />
                          <% end %>
                        </span>
                      </div>
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer group"
                      phx-click="sort"
                      phx-value-field="founder_return"
                    >
                      <div class="flex items-center">
                        Founder Return
                        <span class={"ml-1 text-silly-blue transition-all duration-200 #{if @sort_by == "yield", do: "opacity-100", else: "opacity-0 group-hover:opacity-50"}"}>
                          <%= cond do %>
                            <% @sort_by == "founder_return" && @sort_direction == :desc -> %>
                              <.icon name="hero-chevron-down" class="h-4 w-4" />
                            <% @sort_by == "founder_return" && @sort_direction == :asc -> %>
                              <.icon name="hero-chevron-up" class="h-4 w-4" />
                            <% true -> %>
                              <.icon name="hero-chevron-down" class="h-4 w-4" />
                          <% end %>
                        </span>
                      </div>
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= for {entry, index} <- Enum.with_index(@leaderboard_data) do %>
                    <tr class={"#{if rem(index, 2) == 0, do: "bg-white", else: "bg-gray-50"} hover:bg-gray-100 transition-colors duration-150"}>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900 font-medium">{index + 1}</div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <div class="h-10 w-10 rounded-full bg-silly-purple text-white flex items-center justify-center font-bold">
                            {String.upcase(String.slice(entry.username, 0, 1))}
                          </div>
                          <div class="ml-4">
                            <div class="text-sm font-medium text-gray-900">@{entry.username}</div>
                          </div>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900">{entry.company_name}</div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900 font-semibold">
                          ${format_number(entry.exit_value)}
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900 font-semibold">
                          ${format_number(entry.yield)}
                        </div>
                        <div class="text-xs text-gray-500">
                          {calculate_percentage(entry.yield, entry.exit_value)}% of exit
                        </div>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>

          <div class="mt-8 flex justify-center">
            <a href="/" class="text-silly-blue hover:text-silly-blue/80 font-medium flex items-center">
              <.icon name="hero-arrow-left" class="h-4 w-4 mr-2" /> Back to Home
            </a>
          </div>
        </div>
      </main>

      <.footer />
    </div>
    """
  end

  # Helper function to format large numbers with commas
  defp format_number(number) do
    number
    |> Decimal.to_string()
    |> String.replace(~r/(\d)(?=(\d{3})+(?!\d))/, "\\1,")
  end

  # Helper function to calculate percentage
  defp calculate_percentage(yield, exit_value) do
    percentage = Decimal.div(yield, exit_value) |> Decimal.mult(Decimal.new(100))
    Decimal.round(percentage, 1) |> Decimal.to_string()
  end
end
