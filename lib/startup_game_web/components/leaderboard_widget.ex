defmodule StartupGameWeb.LeaderboardWidget do
  @moduledoc """
  A LiveComponent that displays a leaderboard of top startup exits.
  """

  use StartupGameWeb, :html
  alias StartupGame.Games

  attr :class, :string, default: ""
  attr :limit, :integer, default: 5

  def leaderboard(assigns) do
    # Fetch real leaderboard data
    leaderboard_data = Games.list_leaderboard_data(%{limit: assigns.limit})

    assigns = assign(assigns, :leaderboard_data, leaderboard_data)

    ~H"""
    <div class={"rounded-xl shadow-md overflow-hidden bg-white #{@class}"}>
      <div class="px-4 py-4 bg-silly-blue/10">
        <div class="flex justify-between items-center">
          <h3 class="font-bold text-gray-900">Top Startup Exits</h3>
          <a href="/leaderboard" class="text-silly-blue hover:text-silly-blue/80 text-sm font-medium">
            View All
          </a>
        </div>
      </div>

      <div class="overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th
                scope="col"
                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Rank
              </th>
              <th
                scope="col"
                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Username
              </th>
              <th
                scope="col"
                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Company
              </th>
              <th
                scope="col"
                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Exit Value
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <%= for {entry, index} <- Enum.with_index(@leaderboard_data) do %>
              <tr class="hover:bg-gray-50">
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="text-sm font-medium text-gray-900">{index + 1}</div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="text-sm font-medium text-gray-900">@{entry.username}</div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="text-sm font-medium text-gray-900">{entry.company_name}</div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="text-sm text-gray-900 font-medium">
                    ${format_number(entry.exit_value)}
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  # Helper function to format large numbers with commas
  defp format_number(number) do
    number
    |> Decimal.to_string()
    |> String.replace(~r/(\d)(?=(\d{3})+(?!\d))/, "\\1,")
  end
end
