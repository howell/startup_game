defmodule StartupGameWeb.Admin.UserManagementLive do
  use StartupGameWeb, :live_view

  alias StartupGame.Accounts

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        page_title: "Manage Users",
        users: Accounts.list_users(),
        # For delete confirmation modal
        user_to_delete: nil
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto px-20 mt-20">
      <.header class="mb-6">
        Manage Users
        <:subtitle>View, edit roles, and delete users.</:subtitle>
      </.header>

      <.table id="users" rows={@users}>
        <:col :let={user} label="Email">{user.email}</:col>
        <:col :let={user} label="Username">{user.username || "--"}</:col>
        <:col :let={user} label="Role">
          <.button
            phx-click="update_role"
            phx-value-user-id={user.id}
            phx-value-role={if user.role == :admin, do: "user", else: "admin"}
            class={
              if user.role == :admin,
                do: "bg-yellow-500 hover:bg-yellow-600",
                else: "bg-green-500 hover:bg-green-600"
            }
            disabled={user.id == @current_user.id}
          >
            {if user.role == :admin, do: "Make User", else: "Make Admin"}
          </.button>
        </:col>
        <:col :let={user} label="Joined">{DateTime.to_string(user.inserted_at)}</:col>
        <:action :let={user}>
          <div class="sr-only">
            <.link navigate={~p"/admin/users/#{user.id}"}>Show</.link>
          </div>
          <%= if user.id != @current_user.id do %>
            <.link
              phx-click={JS.push("open_delete_modal", value: %{user_id: user.id})}
              class="text-red-600 hover:text-red-900"
            >
              Delete
            </.link>
          <% else %>
            <span class="text-gray-400 cursor-not-allowed">Delete</span>
          <% end %>
        </:action>
      </.table>

      <%!-- Delete Confirmation Modal --%>
      <.modal
        :if={@user_to_delete}
        id="delete-user-modal"
        show
        on_cancel={JS.push("close_delete_modal")}
      >
        <div class="p-4">
          <h2 class="text-lg font-semibold mb-4">Confirm Deletion</h2>
          <p class="mb-6">
            Are you sure you want to delete user <span class="font-medium"><%= @user_to_delete && @user_to_delete.email %></span>?
            This action cannot be undone.
          </p>
          <.button
            phx-click="delete_user"
            phx-value-user-id={@user_to_delete && @user_to_delete.id}
            class="bg-red-600 hover:bg-red-700"
          >
            Delete User
          </.button>
          <.button phx-click="close_delete_modal" class="ml-4 bg-gray-400 hover:bg-gray-500">
            Cancel
          </.button>
        </div>
      </.modal>
    </div>
    """
  end

  # Event Handlers

  @impl true
  def handle_event("update_role", %{"user-id" => user_id, "role" => role_str}, socket) do
    user = Enum.find(socket.assigns.users, &(&1.id == user_id))
    new_role = String.to_existing_atom(role_str)

    case Accounts.update_user_role(user, %{role: new_role}) do
      {:ok, updated_user} ->
        users = update_user_in_list(socket.assigns.users, updated_user)

        socket =
          socket
          |> put_flash(:info, "User #{updated_user.email} role updated to #{new_role}.")
          |> assign(:users, users)

        {:noreply, socket}

      {:error, changeset} ->
        socket = put_flash(socket, :error, "Failed to update role: #{inspect(changeset.errors)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("open_delete_modal", %{"user_id" => user_id}, socket) do
    # Ensure user_id is converted if necessary, though it should be binary_id string
    user_to_delete = Enum.find(socket.assigns.users, &(&1.id == user_id))
    {:noreply, assign(socket, user_to_delete: user_to_delete)}
  end

  @impl true
  def handle_event("close_delete_modal", _, socket) do
    {:noreply, assign(socket, user_to_delete: nil)}
  end

  @impl true
  def handle_event("delete_user", %{"user-id" => user_id}, socket) do
    user_to_delete = socket.assigns.user_to_delete

    # Double-check we have the correct user, especially if modal could linger
    if user_to_delete && user_to_delete.id == user_id do
      case Accounts.admin_delete_user(user_to_delete) do
        {:ok, _deleted_user} ->
          users = Enum.reject(socket.assigns.users, &(&1.id == user_id))

          socket =
            socket
            |> assign(users: users, user_to_delete: nil)
            |> put_flash(:info, "User #{user_to_delete.email} deleted successfully.")

          {:noreply, socket}

        {:error, changeset} ->
          socket =
            put_flash(socket, :error, "Failed to delete user: #{inspect(changeset.errors)}")
            # Close modal on error too
            |> assign(user_to_delete: nil)

          {:noreply, socket}
      end
    else
      # User ID mismatch or user_to_delete is nil, likely an edge case or stale state
      socket =
        put_flash(socket, :error, "Could not find user to delete.")
        |> assign(user_to_delete: nil)

      {:noreply, socket}
    end
  end

  # Helper to update a user in the list without re-fetching
  defp update_user_in_list(users, updated_user) do
    Enum.map(users, fn user ->
      if user.id == updated_user.id, do: updated_user, else: user
    end)
  end
end
