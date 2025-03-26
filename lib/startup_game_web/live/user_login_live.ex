defmodule StartupGameWeb.UserLoginLive do
  use StartupGameWeb, :live_view
  import StartupGameWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex items-center justify-center p-4">
      <div class="w-full max-w-md bg-white rounded-lg shadow-md p-6">
        <div class="text-center mb-6">
          <h1 class="text-2xl font-bold">Log in to account</h1>
          <p class="text-gray-600 mt-1">
            Enter your credentials to access your account
          </p>
        </div>

        <.simple_form
          for={@form}
          id="login_form"
          action={~p"/users/log_in"}
          phx-update="ignore"
          class="space-y-4"
        >
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            placeholder="you@example.com"
            autocomplete="username"
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-silly-blue focus:border-silly-blue"
          />

          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            placeholder="Enter your password"
            autocomplete="current-password"
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-silly-blue focus:border-silly-blue"
          />

          <div class="flex items-center justify-between">
            <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
            <.link
              href={~p"/users/reset_password"}
              class="text-sm text-silly-blue hover:underline"
            >
              Forgot your password?
            </.link>
          </div>

          <:actions>
            <.button
              type="submit"
              class="w-full bg-silly-blue text-white font-medium py-2 px-4 rounded-md hover:bg-silly-blue/90 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-silly-blue"
              phx-disable-with="Logging in..."
            >
              Log in
            </.button>
          </:actions>
        </.simple_form>

        <div class="mt-6 text-center">
          <p class="text-sm">
            Don't have an account?{" "}
            <.link navigate={~p"/users/register"} class="text-silly-blue hover:underline">
              Sign up
            </.link>
            for an account now.
          </p>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
