defmodule StartupGameWeb.UserSettings.EmailForm do
  @moduledoc """
  A changeset for the email form.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias StartupGame.Accounts.User

  @primary_key false
  embedded_schema do
    field :email, :string
    field :email_confirmation, :string
    field :current_password, :string
  end

  @doc """
  Creates a changeset for the email form.
  """
  def changeset(email_form, attrs, user) do
    email_form
    |> cast(attrs, [:email, :email_confirmation, :current_password])
    |> validate_required([:email, :current_password])
    |> validate_email_format()
    |> validate_confirmation(:email, message: "does not match email")
    |> validate_change(:email, fn :email, email ->
      if email && email != user.email do
        []
      else
        [email: "did not change"]
      end
    end)
  end

  # Validates that the email has proper format.
  defp validate_email_format(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end

  @doc """
  Applies the email change using the Accounts context functions.
  Returns {:ok, user} or {:error, changeset}
  """
  def apply_email_change(email_form, user) do
    # First create a changeset to preserve the form data
    changeset =
      changeset(
        email_form,
        %{
          "email" => email_form.email,
          "email_confirmation" => email_form.email_confirmation,
          "current_password" => email_form.current_password
        },
        user
      )

    if User.valid_password?(user, email_form.current_password) do
      case StartupGame.Accounts.apply_user_email(user, email_form.current_password, %{
             "email" => email_form.email
           }) do
        {:ok, user} -> {:ok, user}
        {:error, changeset} -> {:error, Map.put(changeset, :action, :insert)}
      end
    else
      {:error,
       changeset
       |> Map.put(:action, :insert)
       |> add_error(:current_password, "is incorrect")}
    end
  end
end
