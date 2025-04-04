defmodule StartupGameWeb.Admin.UserManagementLiveTest do
  # Run synchronously
  use StartupGameWeb.ConnCase, async: false

  # Revert to simple import
  import Phoenix.LiveViewTest
  import StartupGame.AccountsFixtures
  # alias StartupGame.Accounts.User # Removed unused alias

  @moduletag :admin

  describe "Admin User Management" do
    setup :register_and_log_in_admin

    test "renders user management page with users", %{conn: conn, admin_user: admin} do
      # Create another user for the list
      regular_user = user_fixture(%{email: "regular@example.com"})

      {:ok, view, html} = live(conn, ~p"/admin/users")

      assert has_element?(view, "h1", "Manage Users")
      # Check table exists
      assert has_element?(view, "#users")

      # Use row IDs for assertions
      admin_row_selector = "#user-#{admin.id}"
      regular_user_row_selector = "#user-#{regular_user.id}"

      assert has_element?(view, admin_row_selector)

      assert Floki.find(html, admin_row_selector <> " td:nth-child(1)")
             |> Floki.text()
             |> String.trim() == admin.email

      assert has_element?(view, regular_user_row_selector)

      assert Floki.find(html, regular_user_row_selector <> " td:nth-child(1)")
             |> Floki.text()
             |> String.trim() == regular_user.email

      assert element(view, admin_row_selector <> " button[disabled]")

      assert Floki.find(
               html,
               admin_row_selector <> " td:nth-child(5) span.text-gray-400.cursor-not-allowed"
             )
             |> Floki.text()
             |> String.trim() ==
               "Delete"

      refute has_element?(
               view,
               admin_row_selector <> " td:nth-child(5) a[phx-click*='open_delete_modal']"
             )
    end

    test "can toggle user role between user and admin", %{conn: conn, admin_user: _admin} do
      user_to_modify = user_fixture(%{email: "toggle@example.com"})

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      user_row_selector = "#user-#{user_to_modify.id}"
      assert has_element?(view, user_row_selector)

      make_admin_button_selector = user_row_selector <> ~s| button[phx-value-role="admin"]|

      make_admin_button = element(view, make_admin_button_selector, "Make Admin")

      updated_html = make_admin_button |> render_click()

      assert updated_html =~ "User #{user_to_modify.email} role updated to admin."

      assert has_element?(view, user_row_selector)

      make_user_button_selector = user_row_selector <> ~s| button[phx-value-role="user"]|

      make_user_button = element(view, make_user_button_selector, "Make User")

      updated_html = make_user_button |> render_click()

      assert updated_html =~ "User #{user_to_modify.email} role updated to user."

      assert has_element?(view, user_row_selector)
    end

    test "can delete a user", %{conn: conn, admin_user: _admin} do
      user_to_delete = user_fixture(%{email: "delete@example.com"})
      user_row_selector = "#user-#{user_to_delete.id}"
      modal_selector = "#delete-user-modal"

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      assert has_element?(view, user_row_selector)

      delete_link_selector = user_row_selector <> ~s| a[phx-click*="open_delete_modal"]|

      delete_link = element(view, delete_link_selector)
      updated_html = delete_link |> render_click()

      assert updated_html =~ "Are you sure you want to delete user"

      element(view, modal_selector <> ~s| button[phx-click="close_delete_modal"]|)
      |> render_click()

      assert has_element?(view, user_row_selector)

      delete_link_selector = user_row_selector <> ~s| a[phx-click*="open_delete_modal"]|

      element(view, delete_link_selector) |> render_click()

      updated_html =
        element(
          view,
          modal_selector <>
            ~s| button[phx-click="delete_user"][phx-value-user-id="#{user_to_delete.id}"]|
        )
        |> render_click()

      updated_html =~ "deleted successfully."

      refute has_element?(view, user_row_selector),
             "Row #{user_row_selector} should have been removed"
    end
  end
end
