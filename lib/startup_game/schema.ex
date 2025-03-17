defmodule StartupGame.Schema do
  @moduledoc """
  A wrapper around Ecto.Schema that sets up some defaults for our schemas.
  In particular:
    - Sets the primary key to be a binary_id
    - Sets the foreign key type to be a binary_id
    - Sets the timestamps type to be utc_datetime_usec
  Inspired by https://johnelmlabs.com/posts/better-mix-phx-new
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end
