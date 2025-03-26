defmodule StartupGameWeb.UserResetPasswordLive do
  use StartupGameWeb, :live_view
  import StartupGameWeb.CoreComponents

  alias StartupGame.Accounts

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex items-center justify-center p-4">
      <div class="w-full max-w-md bg-white rounded-lg shadow-md p-6">
        <div class="text-center mb-6">
          <h1 class="text-2xl font-bold">Reset Password</h1>
          <p class="text-gray-600 mt-1">
            Enter your new password below
          </p>
        </div>

        <.simple_form
          for={@form}
          id="reset_password_form"
          phx-submit="reset_password"
          phx-change="validate"
          class="space-y-4"
        >
          <.input
            field={@form[:password]}
            type="password"
            label="New password"
            placeholder="Enter your new password"
            autocomplete="new-password"
            phx-debounce="300"
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-silly-blue focus:border-silly-blue"
          />

          <.input
            field={@form[:password_confirmation]}
            type="password"
            label="Confirm new password"
            placeholder="Confirm your new password"
            autocomplete="new-password"
            phx-debounce="300"
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-silly-blue focus:border-silly-blue"
          />

          <:actions>
            <.button
              phx-disable-with="Resetting..."
              class="w-full bg-silly-blue text-white font-medium py-2 px-4 rounded-md hover:bg-silly-blue/90 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-silly-blue"
            >
              Reset Password
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

  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{user: user} ->
          Accounts.change_user_password(user)

        _ ->
          %{}
      end

    {:ok, assign_form(socket, form_source), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully.")
         |> redirect(to: ~p"/users/log_in")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_password(socket.assigns.user, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/")
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "user"))
  end
end
