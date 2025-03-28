defmodule StartupGameWeb.LeaderboardWidget do
  @moduledoc """
  A LiveComponent that displays a leaderboard of top startup exits.
  """

  use StartupGameWeb, :live_component
  alias StartupGame.Games
  alias StartupGameWeb.GameLive.Helpers.GameFormatters

  @type t :: %{
          id: String.t(),
          class: String.t(),
          limit: non_neg_integer(),
          sort_by: String.t(),
          sort_direction: :asc | :desc
        }

  @doc """
  Initialize the component state based on assigned props.
  """
  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(
        :leaderboard_data,
        leaderboard_entries(assigns.limit, assigns.sort_by, assigns.sort_direction)
      )

    {:ok, socket}
  end

  @doc """
  Renders a leaderboard component showing top startup exits.
  """
  # Props that can be passed to the component
  attr :class, :string, default: ""
  attr :limit, :integer, default: 5
  attr :sort_by, :string, default: "exit_value"
  attr :sort_direction, :atom, default: :desc
  attr :leaderboard_data, :list, required: true
  attr :myself, :any

  @impl true
  def render(assigns) do
    ~H"""
    <div class={"rounded-xl shadow-md overflow-hidden bg-white #{@class}"}>
      <.header_section />
      <.table_section
        leaderboard_data={@leaderboard_data}
        sort_by={@sort_by}
        sort_direction={@sort_direction}
        myself={@myself}
      />
    </div>
    """
  end

  defp leaderboard_entries(limit, sort_by, sort_direction) do
    Games.list_leaderboard_data(%{
      limit: limit,
      sort_by: sort_by,
      sort_direction: sort_direction
    })
  end

  @doc """
  Handle the sort event directly within the component.
  """
  @impl true
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

    comparison = if new_direction == :desc, do: &Decimal.gte?/2, else: &Decimal.lte?/2
    key = String.to_existing_atom(new_field)

    sorted_data =
      Enum.sort_by(socket.assigns.leaderboard_data, &Map.get(&1, key), comparison)

    {:noreply,
     socket
     |> assign(
       leaderboard_data: sorted_data,
       sort_by: new_field,
       sort_direction: new_direction
     )}
  end

  @doc """
  Renders the header section of the leaderboard with title and view all link.
  """
  def header_section(assigns) do
    ~H"""
    <div class="px-4 py-4 bg-silly-blue/10">
      <div class="flex justify-between items-center">
        <h3 class="font-bold text-gray-900">Top Startup Exits</h3>
        <a href="/leaderboard" class="text-silly-blue hover:text-silly-blue/80 text-sm font-medium">
          View All
        </a>
      </div>
    </div>
    """
  end

  attr :leaderboard_data, :list, required: true
  attr :sort_by, :string, required: true
  attr :sort_direction, :atom, required: true
  attr :myself, :any

  @doc """
  Renders the table section of the leaderboard with sortable columns.
  """
  def table_section(assigns) do
    ~H"""
    <div class="overflow-hidden">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <.table_header>Rank</.table_header>
            <.table_header>Username</.table_header>
            <.table_header>Company</.table_header>
            <.sortable_header
              field="exit_value"
              label="Exit Value"
              sort_by={@sort_by}
              sort_direction={@sort_direction}
              myself={@myself}
            />
            <.sortable_header
              field="yield"
              label="Founder Return"
              sort_by={@sort_by}
              sort_direction={@sort_direction}
              myself={@myself}
            />
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <%= for {entry, index} <- Enum.with_index(@leaderboard_data) do %>
            <.leaderboard_row entry={entry} index={index} />
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  attr :field, :string, required: true
  attr :label, :string, required: true
  attr :sort_by, :string, required: true
  attr :sort_direction, :atom, required: true
  attr :myself, :any
  slot :inner_block

  @doc """
  Renders a sortable table header for the leaderboard.
  Emits "sort" event with field value.
  """
  def sortable_header(assigns) do
    ~H"""
    <th
      scope="col"
      class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer group"
      phx-click="sort"
      phx-value-field={@field}
      phx-target={@myself}
    >
      <div class="flex items-center">
        {@label}
        <span class={"ml-1 text-silly-blue transition-all duration-200 #{if @sort_by == @field, do: "opacity-100", else: "opacity-0 group-hover:opacity-50"}"}>
          <%= cond do %>
            <% @sort_by == @field && @sort_direction == :desc -> %>
              <.icon name="hero-chevron-down" class="h-4 w-4" />
            <% @sort_by == @field && @sort_direction == :asc -> %>
              <.icon name="hero-chevron-up" class="h-4 w-4" />
            <% true -> %>
              <.icon name="hero-chevron-down" class="h-4 w-4" />
          <% end %>
        </span>
      </div>
    </th>
    """
  end

  slot :inner_block, required: true

  @doc """
  Renders a standard table header cell.
  """
  def table_header(assigns) do
    ~H"""
    <th
      scope="col"
      class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
    >
      {render_slot(@inner_block)}
    </th>
    """
  end

  attr :class, :string, default: "font-medium"
  slot :inner_block, required: true

  @doc """
  Renders a standard table cell with consistent styling.
  """
  def table_cell(assigns) do
    ~H"""
    <div class={"text-sm text-gray-900 #{@class}"}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  slot :inner_block, required: true

  @doc """
  Renders a standard table cell container with consistent styling.
  """
  def row_cell(assigns) do
    ~H"""
    <td class="px-4 py-3 whitespace-nowrap">
      {render_slot(@inner_block)}
    </td>
    """
  end

  attr :entry, :map, required: true
  attr :index, :integer, required: true

  @doc """
  Renders a single row in the leaderboard table.
  """
  def leaderboard_row(assigns) do
    ~H"""
    <tr class={"#{if rem(@index, 2) == 0, do: "bg-white", else: "bg-gray-50"} hover:bg-gray-100 transition-colors duration-150"}>
      <.row_cell>
        <.table_cell>{@index + 1}</.table_cell>
      </.row_cell>
      <.row_cell>
        <.table_cell>@{@entry.username}</.table_cell>
      </.row_cell>
      <.row_cell>
        <.table_cell>{@entry.company_name}</.table_cell>
      </.row_cell>
      <.row_cell>
        <.table_cell>
          ${GameFormatters.format_money(@entry.exit_value)}
        </.table_cell>
      </.row_cell>
      <.row_cell>
        <div>
          <.table_cell class="font-semibold">
            ${GameFormatters.format_money(@entry.yield)}
          </.table_cell>
          <div class="text-xs text-gray-500">
            {calculate_percentage(@entry.yield, @entry.exit_value)}% of exit
          </div>
        </div>
      </.row_cell>
    </tr>
    """
  end

  @doc """
  Calculates the percentage of yield relative to exit value.
  """
  def calculate_percentage(yield, exit_value) do
    percentage = Decimal.div(yield, exit_value) |> Decimal.mult(Decimal.new(100))
    Decimal.round(percentage, 1) |> Decimal.to_string()
  end
end
