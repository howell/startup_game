defmodule StartupGameWeb.Plugs.RequireAdminAuth do
  @moduledoc """
  Plug to ensure the current user is authenticated and has the :admin role.

  Redirects non-admins to the root path with an error flash message.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]

  # alias StartupGameWeb.Router.Helpers, as: Routes # Not needed if using sigil

  @doc """
  Initializes the plug options. Currently unused.
  """
  def init(opts), do: opts

  @doc """
  Checks if the current user is an administrator.

  If the user is logged in and has the `:admin` role, the connection continues.
  Otherwise, it puts an error flash message, redirects to the root path,
  and halts the connection.
  """
  def call(conn, _opts) do
    user = conn.assigns.current_user

    if user && user.role == :admin do
      conn
    else
      conn
      |> put_flash(:error, "You must be an administrator to access this page.")
      # Redirect to root path
      |> redirect(to: "/")
      |> halt()
    end
  end
end
