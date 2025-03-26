defmodule StartupGameWeb.UserRegistrationLiveTest do
  use StartupGameWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import StartupGame.AccountsFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Create an account"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "with spaces", "password" => "too short"})

      assert result =~ "Create an account"
      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 12 character"
    end
  end

  describe "register user" do
    test "creates account and logs the user in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      email = unique_user_email()
      password = "valid_password12345"

      # Submit the form with valid values
      lv
      |> element("#registration_form")
      |> render_submit(%{
        user: %{
          "email" => email,
          "password" => password,
          "password_confirmation" => password
        }
      })

      # Verify the account was created
      user = StartupGame.Accounts.get_user_by_email(email)
      assert user

      # Verify we can log in with the new credentials
      new_conn =
        build_conn()
        |> post("/users/log_in", %{
          "user" => %{"email" => email, "password" => password}
        })

      assert redirected_to(new_conn) == "/"
      assert get_session(new_conn, :user_token)
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      user = user_fixture(%{email: "test@email.com"})

      # Submit the form with existing email
      lv
      |> form("#registration_form",
        user: %{
          "email" => user.email,
          "password" => "valid_password",
          "password_confirmation" => "valid_password"
        }
      )
      |> render_submit()

      # The page should reload with an error message
      assert render(lv) =~ "Oops, something went wrong"

      # Check that we're still on the registration page
      assert render(lv) =~ "Create an account"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      {:ok, _login_live, login_html} =
        lv
        |> element(~s|a:fl-contains("Log in")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/users/log_in")

      assert login_html =~ "Log in"
    end
  end
end
