defmodule Mix.Tasks.Users.SetRole do
  use Mix.Task

  require Logger

  @shortdoc "Sets the role for a user by email"
  @moduledoc """
  Sets the role (:user or :admin) for a user identified by their email address.

  ## Examples

      mix users.set_role user@example.com admin
      mix users.set_role another@example.com user

  This task requires the application to be started to access the database.
  """

  alias StartupGame.Accounts

  @impl Mix.Task
  def run(args) do
    # Ensure the application is started so Repo is available
    Mix.Task.run("app.start")

    case args do
      [email, role_str] ->
        set_user_role(email, role_str)

      _ ->
        Logger.error("Invalid arguments. Usage: mix users.set_role <email> <user|admin>")
        exit({:shutdown, 1})
    end
  end

  def set_user_role(email, role_str) do
    try do
      case String.to_existing_atom(role_str) do
        role when role in [:user, :admin] ->
          case Accounts.get_user_by_email(email) do
            nil ->
              Logger.error("User with email #{email} not found.")
              exit({:shutdown, 1})

            user ->
              case Accounts.update_user_role(user, %{role: role}) do
                {:ok, updated_user} ->
                  Logger.info(
                    "Successfully set role for #{updated_user.email} to #{updated_user.role}."
                  )

                {:error, changeset} ->
                  Logger.error("Failed to update role for #{email}: #{inspect(changeset.errors)}")

                  exit({:shutdown, 1})
              end
          end

        _invalid_role ->
          Logger.error("Invalid role: '#{role_str}'. Must be 'user' or 'admin'.")
          exit({:shutdown, 1})
      end
    catch
      # Catch error if role_str is not a valid atom representation (e.g., "foo")
      :error, %ArgumentError{} ->
        Logger.error("Invalid role: '#{role_str}'. Must be 'user' or 'admin'.")
        exit({:shutdown, 1})
    end
  end
end
