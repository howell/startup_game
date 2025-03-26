defmodule StartupGameWeb.UserForgotPasswordLive do
  use StartupGameWeb, :live_view
  import StartupGameWeb.CoreComponents

  alias StartupGame.Accounts

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex items-center justify-center p-4">
      <div class="w-full max-w-md bg-white rounded-lg shadow-md p-6">
        <div class="text-center mb-6">
          <h1 class="text-2xl font-bold">Reset password</h1>
          <p class="text-gray-600 mt-1">
            Enter your email address and we'll send you a link to reset your password
          </p>
        </div>

        <.simple_form
          for={@form}
          id="reset_password_form"
          phx-submit="send_email"
          phx-change="validate"
          class="space-y-4"
        >
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

          <:actions>
            <.button
              phx-disable-with="Sending reset link..."
              class="w-full bg-silly-blue text-white font-medium py-2 px-4 rounded-md hover:bg-silly-blue/90 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-silly-blue"
            >
              Send reset link
            </.button>
          </:actions>
        </.simple_form>

        <div class="mt-6 text-center">
          <.link navigate={~p"/users/log_in"} class="text-silly-blue hover:underline">
            Back to log in
          </.link>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("validate", %{"user" => %{"email" => email}}, socket) do
    form =
      %{"email" => email}
      |> validate_email()
      |> to_form(as: "user")

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end

  defp validate_email(params) do
    types = %{email: :string}

    {%{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required([:email], message: "is required")
    |> Ecto.Changeset.validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email address")
  end
end
