defmodule StartupGame.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `StartupGame.Accounts` context.
  """

  # Added alias for clarity
  alias StartupGame.Accounts

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def unique_username, do: "user#{System.unique_integer([:positive])}"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: attrs[:email] || unique_user_email(),
      username: attrs[:username] || unique_username(),
      password: valid_user_password()
      # Note: Role is not set here, it defaults in the schema or registration
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      # Use alias
      |> Accounts.register_user()

    user
  end

  @doc """
  Creates an admin user.

  Accepts optional attributes which are passed to `user_fixture`.
  """
  def admin_user_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)

    # Use alias
    {:ok, admin_user} = Accounts.update_user_role(user, %{role: :admin})

    admin_user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
