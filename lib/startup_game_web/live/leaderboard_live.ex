defmodule StartupGameWeb.LeaderboardLive do
  use StartupGameWeb, :live_view
  alias StartupGame.Games
  alias StartupGameWeb.LeaderboardWidget

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Leaderboard"
     )}
  end

  @doc """
  Handles the leaderboard-sort event from the leaderboard component.
  Updates the sort field and direction, then fetches fresh data.
  """
  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("leaderboard-sort", %{"field" => field, "id" => _id}, socket) do
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
    <div class="container pt-20 mx-auto px-4">
      <div class="flex flex-col items-center mb-8">
        <h1 class="text-3xl font-bold text-gray-900 mb-2">Startup Success Leaderboard</h1>
        <p class="text-gray-600 text-center max-w-2xl">
          See the most successful founders and their companies in SillyConValley.
          Sort by either exit value or founder return to discover different success stories.
        </p>
      </div>

      <.live_component
        module={LeaderboardWidget}
        id="main-leaderboard"
        class="w-full"
        sort_by="exit_value"
        sort_direction={:desc}
        limit={50}
        include_case_studies={true}
      />

      <div class="mt-8 flex justify-center">
        <a href="/" class="text-silly-blue hover:text-silly-blue/80 font-medium flex items-center">
          <.icon name="hero-arrow-left" class="h-4 w-4 mr-2" /> Back to Home
        </a>
      </div>
    </div>
    """
  end
end
