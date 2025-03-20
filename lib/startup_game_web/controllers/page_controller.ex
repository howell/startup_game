defmodule StartupGameWeb.PageController do
  use StartupGameWeb, :controller

  def home(conn, _params) do
    # Use the app layout for consistency with the rest of the application
    render(conn, :home)
  end
end
