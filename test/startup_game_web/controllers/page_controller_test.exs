defmodule StartupGameWeb.PageControllerTest do
  use StartupGameWeb.ConnCase
  import Phoenix.LiveViewTest

  test "GET /", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")

    assert html =~
             "Navigate ridiculous scenarios"
  end
end
