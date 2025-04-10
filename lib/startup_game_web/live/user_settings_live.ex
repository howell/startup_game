defmodule StartupGameWeb.UserSettingsLive do
  use StartupGameWeb, :live_view
  import StartupGameWeb.CoreComponents

  alias StartupGame.Accounts
  alias StartupGame.Accounts.User
  alias StartupGameWeb.UserSettings.EmailForm

  require Logger

  # Tab navigation component
  attr :active_tab, :string, required: true

  def settings_tab_bar(assigns) do
    ~H"""
    <div class="mb-6 bg-white rounded-md p-2 inline-flex">
      <.button
        phx-click="set_tab"
        phx-value-tab="profile"
        type="button"
        class={
          "px-4 py-2 rounded-md text-sm font-medium #{
            if @active_tab == "profile",
            do: "",
            else: "opacity-50 hover:opacity-75"
          }"
        }
      >
        Profile
      </.button>
      <.button
        phx-click="set_tab"
        phx-value-tab="security"
        type="button"
        class={
          "px-4 py-2 rounded-md text-sm font-medium #{
            if @active_tab == "security",
            do: "",
            else: "opacity-50 hover:opacity-75"
          }"
        }
      >
        Security
      </.button>
    </div>
    """
  end

  # Username section component
  attr :username_form, :any, required: true
  attr :username_form_current_password, :string, default: nil
  attr :current_user, :any, required: true

  def username_section(assigns) do
    ~H"""
    <div class={card_class()}>
      <div class="mb-4">
        <h2 class="text-xl font-semibold">Username</h2>
        <p class="text-gray-600 text-sm mt-1">
          Update your username
        </p>
      </div>

      <.simple_form
        for={@username_form}
        id="username_form"
        phx-submit="update_username"
        phx-change="validate_username"
        class="space-y-4"
      >
        <.input
          field={@username_form[:username]}
          type="text"
          label="Username"
          phx-debounce="300"
          class={input_class()}
        />

        <.input
          field={@username_form[:current_password]}
          name="current_password"
          id="current_password_for_username"
          type="password"
          label="Current password"
          value={@username_form_current_password}
          phx-debounce="300"
          class={input_class()}
          required
        />

        <:actions>
          <.button phx-disable-with="Updating username..." class={button_class()}>
            Update Username
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  # Email section component
  attr :email_form, :any, required: true
  attr :current_user, :any, required: true

  def email_section(assigns) do
    ~H"""
    <div class={card_class()}>
      <div class="mb-4">
        <h2 class="text-xl font-semibold">Email Address</h2>
        <p class="text-gray-600 text-sm mt-1">
          Update your email address
        </p>
      </div>

      <div class="mb-4 p-3 bg-gray-50 rounded-md">
        <div class="text-sm font-medium text-gray-700">Current Email Address</div>
        <div class="mt-1 text-gray-900">{@current_user.email}</div>
      </div>

      <.simple_form
        for={@email_form}
        id="email_form"
        phx-submit="update_email"
        phx-change="validate_email"
        class="space-y-4"
      >
        <.input
          field={@email_form[:email]}
          type="email"
          label="New Email Address"
          phx-debounce="300"
          class={input_class()}
          required
        />

        <.input
          field={@email_form[:email_confirmation]}
          type="email"
          label="Confirm New Email Address"
          phx-debounce="300"
          class={input_class()}
          required
        />

        <.input
          field={@email_form[:current_password]}
          type="password"
          label="Current password"
          phx-debounce="300"
          class={input_class()}
          required
        />

        <:actions>
          <.button phx-disable-with="Updating email..." class={button_class()}>
            Update Email
          </.button>
        </:actions>
      </.simple_form>

      <div class="mt-4 text-sm text-gray-500">
        Account created on {format_date(@current_user.inserted_at)}
      </div>
    </div>
    """
  end

  # Password change section component
  attr :password_form, :any, required: true
  attr :current_password, :string, default: nil
  attr :trigger_submit, :boolean, default: false
  attr :current_email, :string, required: true

  def password_change_section(assigns) do
    ~H"""
    <div class={card_class()}>
      <div class="mb-4">
        <h2 class="text-xl font-semibold">Change Password</h2>
        <p class="text-gray-600 text-sm mt-1">
          Update your password to keep your account secure
        </p>
      </div>

      <.simple_form
        for={@password_form}
        id="password_form"
        action={~p"/users/log_in?_action=password_updated"}
        method="post"
        phx-change="validate_password"
        phx-submit="update_password"
        phx-trigger-action={@trigger_submit}
        class="space-y-4"
      >
        <input
          name={@password_form[:email].name}
          type="hidden"
          id="hidden_user_email"
          value={@current_email}
        />

        <.input
          field={@password_form[:password]}
          type="password"
          label="New Password"
          placeholder="Enter your new password"
          phx-debounce="300"
          class={input_class()}
          required
        />

        <.input
          field={@password_form[:password_confirmation]}
          type="password"
          label="Confirm New Password"
          placeholder="Confirm your new password"
          phx-debounce="300"
          class={input_class()}
          required
        />

        <.input
          field={@password_form[:current_password]}
          name="current_password"
          type="password"
          label="Current Password"
          id="current_password_for_password"
          value={@current_password}
          phx-debounce="300"
          class={input_class()}
          required
        />

        <:actions>
          <.button phx-disable-with="Changing password..." class={button_class()}>
            Change Password
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  # Visibility settings section component
  attr :visibility_form, :any, required: true
  attr :current_user, :any, required: true

  def visibility_settings_section(assigns) do
    ~H"""
    <div class={card_class()}>
      <div class="mb-4">
        <h2 class="text-xl font-semibold">Game Visibility Settings</h2>
        <p class="text-gray-600 text-sm mt-1">
          Control how your completed games are shared
        </p>
      </div>

      <.simple_form
        for={@visibility_form}
        id="visibility_form"
        phx-submit="update_visibility"
        class="space-y-4"
      >
        <div class="space-y-2">
          <label class="block text-sm font-medium text-gray-700">
            Default visibility for completed games
          </label>

          <div class="mt-2 space-y-2">
            <label class="inline-flex items-center">
              <input
                type="radio"
                name={@visibility_form[:default_game_visibility].name}
                value="public"
                checked={to_string(@visibility_form[:default_game_visibility].value) == "public"}
                phx-click="set_visibility"
                phx-value-visibility="public"
                class="h-4 w-4 text-silly-blue focus:ring-silly-blue"
              />
              <span class="ml-2 text-sm text-gray-700">
                Public - Share my games on the leaderboard (if eligible)
              </span>
            </label>

            <label class="inline-flex items-center">
              <input
                type="radio"
                name={@visibility_form[:default_game_visibility].name}
                value="private"
                checked={to_string(@visibility_form[:default_game_visibility].value) == "private"}
                phx-click="set_visibility"
                phx-value-visibility="private"
                class="h-4 w-4 text-silly-blue focus:ring-silly-blue"
              />
              <span class="ml-2 text-sm text-gray-700">
                Private - Keep my games private by default
              </span>
            </label>
          </div>
        </div>

        <div class="mt-2 text-sm text-gray-500">
          This setting controls the default visibility of your completed games. You can still change the visibility of individual games later.
        </div>

        <:actions>
          <.button phx-disable-with="Updating settings..." class={button_class()}>
            Update Visibility Settings
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  # Danger zone section component
  attr :show_delete_modal, :boolean, default: false

  def danger_zone_section(assigns) do
    ~H"""
    <div class={"#{card_class()} border border-red-200"}>
      <div class="mb-4">
        <h2 class="text-xl font-semibold text-red-600">Danger Zone</h2>
        <p class="text-gray-600 text-sm mt-1">
          Permanent actions that cannot be undone
        </p>
      </div>

      <.button phx-click="show_delete_modal" type="button" class={danger_button_class()}>
        Delete Account
      </.button>

      <%= if @show_delete_modal do %>
        <.delete_account_modal />
      <% end %>
    </div>
    """
  end

  # Delete account modal component
  def delete_account_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg p-6 w-full max-w-md">
        <h3 class="text-xl font-bold mb-2">Are you sure?</h3>
        <p class="text-gray-600 mb-4">
          This action cannot be undone. This will permanently delete your
          account and remove all your data from our servers.
        </p>

        <.form for={%{}} as={:delete_form} phx-submit="delete_account" class="mt-6">
          <.input
            type="password"
            name="current_password"
            label="Enter your password to confirm"
            placeholder="Your current password"
            required
            value=""
            class={input_class()}
          />

          <div class="flex flex-col sm:flex-row gap-2 mt-4">
            <.button
              type="button"
              phx-click="cancel_delete"
              class="sm:flex-1 px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-silly-blue"
            >
              Cancel
            </.button>
            <.button type="submit" class={"sm:flex-1 #{danger_button_class()}"}>
              Delete Account
            </.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  # Main render function
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col">
      <main class="flex-1 py-8 px-4 bg-gray-50">
        <div class="max-w-4xl mx-auto">
          <h1 class="text-3xl font-bold mb-6">Account Settings</h1>

          <.settings_tab_bar active_tab={@active_tab} />

          <%= if @active_tab == "profile" do %>
            <div class="space-y-6">
              <.username_section
                username_form={@username_form}
                username_form_current_password={@username_form_current_password}
                current_user={@current_user}
              />
              <.email_section email_form={@email_form} current_user={@current_user} />
              <.visibility_settings_section
                visibility_form={@visibility_form}
                current_user={@current_user}
              />
            </div>
          <% else %>
            <div class="space-y-6">
              <.password_change_section
                password_form={@password_form}
                current_password={@current_password}
                trigger_submit={@trigger_submit}
                current_email={@current_email}
              />
              <.danger_zone_section show_delete_modal={@show_delete_modal} />
            </div>
          <% end %>
        </div>
      </main>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    # Create an empty email form
    empty_email_form = %EmailForm{email: "", email_confirmation: ""}
    username_changeset = User.username_changeset(user, %{})
    password_changeset = Accounts.change_user_password(user)
    visibility_changeset = Accounts.change_user_visibility_settings(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:username_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(EmailForm.changeset(empty_email_form, %{}, user)))
      |> assign(:username_form, to_form(username_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:visibility_form, to_form(visibility_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:active_tab, "profile")
      |> assign(:show_delete_modal, false)

    {:ok, socket}
  end

  # Tab navigation
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  # Username form events
  def handle_event("validate_username", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    username_form =
      socket.assigns.current_user
      |> User.username_changeset(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply,
     assign(socket, username_form: username_form, username_form_current_password: password)}
  end

  def handle_event("update_username", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_username(user, password, user_params) do
      {:ok, _user} ->
        info = "Username updated successfully."

        {:noreply,
         socket |> put_flash(:info, info) |> assign(username_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :username_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  # Email form events
  def handle_event("validate_email", %{"email_form" => params}, socket) do
    user = socket.assigns.current_user

    email_form =
      %EmailForm{}
      |> EmailForm.changeset(params, user)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", %{"email_form" => params}, socket) do
    user = socket.assigns.current_user

    # Safely extract only the fields we need
    email_form = %EmailForm{
      email: params["email"],
      email_confirmation: params["email_confirmation"],
      current_password: params["current_password"]
    }

    # Add logging for security events
    Logger.info("Email change attempt for user #{user.id}")

    case EmailForm.apply_email_change(email_form, user) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        Logger.info("Email change confirmation sent for user #{user.id}")

        {:noreply,
         socket
         |> put_flash(
           :info,
           "A link to confirm your email change has been sent to the new address."
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(changeset))}
    end
  end

  # Password form events
  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  # Visibility settings form events
  def handle_event("set_visibility", %{"visibility" => visibility}, socket) do
    visibility_form =
      socket.assigns.current_user
      |> Accounts.change_user_visibility_settings(%{default_game_visibility: visibility})
      |> to_form()

    {:noreply, assign(socket, :visibility_form, visibility_form)}
  end

  def handle_event("update_visibility", %{"user" => user_params}, socket) do
    user = socket.assigns.current_user

    case Accounts.update_user_visibility_settings(user, user_params) do
      {:ok, user} ->
        info = "Game visibility settings updated successfully."
        visibility_form = user |> Accounts.change_user_visibility_settings() |> to_form()

        {:noreply,
         socket
         |> put_flash(:info, info)
         |> assign(:visibility_form, visibility_form)
         |> assign(:current_user, user)}

      {:error, changeset} ->
        {:noreply, assign(socket, :visibility_form, to_form(changeset))}
    end
  end

  # Delete account modal events
  def handle_event("show_delete_modal", _params, socket) do
    {:noreply, assign(socket, :show_delete_modal, true)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, :show_delete_modal, false)}
  end

  def handle_event("delete_account", %{"current_password" => password}, socket) do
    user = socket.assigns.current_user

    case Accounts.delete_user(user, password) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account deleted successfully.")
         |> redirect(to: ~p"/")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Incorrect password. Account not deleted.")
         |> assign(:show_delete_modal, false)}
    end
  end

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y")
  end

  # Common input field styling
  defp input_class do
    "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-silly-blue focus:border-silly-blue"
  end

  defp button_class do
    "bg-silly-blue text-white font-medium py-2 px-4 rounded-md hover:bg-silly-blue/90 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-silly-blue"
  end

  defp danger_button_class do
    "bg-red-600 text-white font-medium py-2 px-4 rounded-md hover:bg-red-700 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
  end

  defp card_class do
    "bg-white rounded-lg shadow-md p-6"
  end
end
