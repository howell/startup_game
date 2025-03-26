defmodule StartupGameWeb.UserRegistrationLive do
  use StartupGameWeb, :live_view
  import StartupGameWeb.CoreComponents

  alias StartupGame.Accounts
  alias StartupGame.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex items-center justify-center p-4">
      <div class="w-full max-w-md bg-white rounded-lg shadow-md p-6">
        <div class="text-center mb-6">
          <h1 class="text-2xl font-bold">Create an account</h1>
          <p class="text-gray-600 mt-1">
            Enter your email below to create your account
          </p>
        </div>

        <.simple_form
          for={@form}
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          phx-trigger-action={@trigger_submit}
          action={~p"/users/log_in?_action=registered"}
          method="post"
          class="space-y-4"
        >
          <.error :if={@check_errors}>
            Oops, something went wrong! Please check the errors below.
          </.error>

          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            placeholder="you@example.com"
            autocomplete="email"
            phx-debounce="300"
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-silly-blue focus:border-silly-blue"
          />

          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            placeholder="Create a password"
            autocomplete="new-password"
            phx-debounce="300"
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-silly-blue focus:border-silly-blue"
          />

          <.input
            field={@form[:password_confirmation]}
            type="password"
            label="Confirm Password"
            placeholder="Confirm your password"
            autocomplete="new-password"
            phx-debounce="300"
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-silly-blue focus:border-silly-blue"
          />

          <:actions>
            <.button
              phx-disable-with="Creating account..."
              class="w-full bg-silly-blue text-white font-medium py-2 px-4 rounded-md hover:bg-silly-blue/90 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-silly-blue"
            >
              Create Account
            </.button>
          </:actions>
        </.simple_form>

        <div class="mt-6 space-y-2">
          <p class="text-sm text-center text-gray-500">
            By creating an account, you agree to our Terms of Service and Privacy Policy
          </p>
          <p class="text-sm text-center">
            Already have an account?{" "}
            <.link navigate={~p"/users/log_in"} class="text-silly-blue hover:underline">
              Log in
            </.link>
          </p>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    # Ensure passwords match before attempting registration
    if user_params["password"] != user_params["password_confirmation"] do
      changeset =
        %User{}
        |> Accounts.change_user_registration(user_params)
        |> Ecto.Changeset.add_error(:password_confirmation, "does not match password")

      {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    else
      case Accounts.register_user(user_params) do
        {:ok, user} ->
          {:ok, _} =
            Accounts.deliver_user_confirmation_instructions(
              user,
              &url(~p"/users/confirm/#{&1}")
            )

          changeset = Accounts.change_user_registration(user)
          {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
      end
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)

    # Add additional validation for password confirmation
    changeset =
      if user_params["password"] && user_params["password_confirmation"] &&
           user_params["password"] != user_params["password_confirmation"] do
        Ecto.Changeset.add_error(changeset, :password_confirmation, "does not match password")
      else
        changeset
      end

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
