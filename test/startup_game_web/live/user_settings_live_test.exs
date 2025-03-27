defmodule StartupGameWeb.UserSettingsLiveTest do
  use StartupGameWeb.ConnCase, async: true

  alias StartupGame.Accounts
  import Phoenix.LiveViewTest
  import StartupGame.AccountsFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, lv, html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/settings")

      assert html =~ "Username"
      assert html =~ "Email Address"

      # Click on the Security tab to see the Change Password section
      html = lv |> element("button", "Security") |> render_click()
      assert html =~ "Change Password"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/users/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{password: password})
      %{conn: log_in_user(conn, user), user: user, password: password}
    end

    test "updates the user email", %{conn: conn, password: password, user: user} do
      new_email = unique_user_email()

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#email_form", %{
          "email_form" => %{
            "email" => new_email,
            "email_confirmation" => new_email,
            "current_password" => password
          }
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_user_by_email(user.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "email_form" => %{
            "email" => "with spaces",
            "email_confirmation" => "with spaces",
            "current_password" => "invalid"
          }
        })

      assert result =~ "Email Address"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, user: _user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#email_form", %{
          "email_form" => %{
            "email" => "different@example.com",
            "email_confirmation" => "different@example.com",
            "current_password" => "invalidpassword"
          }
        })
        |> render_submit()

      assert result =~ "different@example.com"
      assert result =~ "is incorrect"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{password: password})
      %{conn: log_in_user(conn, user), user: user, password: password}
    end

    test "updates the user password", %{conn: conn, user: user, password: password} do
      new_password = valid_user_password()

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      # Click on the Security tab to access the password form
      lv |> element("button", "Security") |> render_click()

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "user" => %{
            "email" => user.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/users/settings"

      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_user_by_email_and_password(user.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      # Click on the Security tab to access the password form
      lv |> element("button", "Security") |> render_click()

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      # Click on the Security tab to access the password form
      lv |> element("button", "Security") |> render_click()

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      user = user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{conn: log_in_user(conn, user), token: token, email: email, user: user}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end

  describe "Visibility settings" do
    setup :register_and_log_in_user

    test "renders visibility settings form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/settings")

      # Check that both radio buttons are present
      assert has_element?(view, "input[type='radio'][value='public']")
      assert has_element?(view, "input[type='radio'][value='private']")

      # Check that private is selected by default (schema default)
      assert has_element?(
               view,
               "input[type='radio'][value='private'][checked]"
             )
    end

    test "updates visibility settings successfully", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/users/settings")

      # Submit form with valid data
      assert view
             |> form("#visibility_form", %{
               "user" => %{"default_game_visibility" => "public"}
             })
             |> render_submit()

      # Flash message should appear
      assert render(view) =~ "Game visibility settings updated successfully"

      # Verify the database was updated
      updated_user = Accounts.get_user!(user.id)
      assert updated_user.default_game_visibility == :public

      # Verify the form reflects the new value
      assert has_element?(
               view,
               "input[type='radio'][value='public'][checked]"
             )
    end

    test "maintains visibility setting after update", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/settings")

      # Change to public
      assert view
             |> form("#visibility_form", %{
               "user" => %{"default_game_visibility" => "public"}
             })
             |> render_submit()

      # Verify it stays public
      assert has_element?(
               view,
               "input[type='radio'][value='public'][checked]"
             )

      # Change back to private
      assert view
             |> form("#visibility_form", %{
               "user" => %{"default_game_visibility" => "private"}
             })
             |> render_submit()

      # Verify it stays private
      assert has_element?(
               view,
               "input[type='radio'][value='private'][checked]"
             )
    end

    test "handles radio button change events correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/settings")

      # Simulate clicking the public radio button
      assert view
             |> element("input[type='radio'][value='public']")
             |> render_click()

      # Verify the form data was updated
      assert has_element?(
               view,
               "input[type='radio'][value='public'][checked]"
             )

      # Simulate clicking the private radio button
      assert view
             |> element("input[type='radio'][value='private']")
             |> render_click()

      # Verify the form data was updated
      assert has_element?(
               view,
               "input[type='radio'][value='private'][checked]"
             )
    end

    test "preserves visibility setting after navigation", %{conn: conn, user: user} do
      # First set the visibility to public
      {:ok, _user} =
        Accounts.update_user_visibility_settings(user, %{default_game_visibility: :public})

      # Navigate to settings page
      {:ok, view, _html} = live(conn, ~p"/users/settings")

      # Verify the public radio button is checked
      assert has_element?(
               view,
               "input[type='radio'][value='public'][checked]"
             )
    end
  end
end
