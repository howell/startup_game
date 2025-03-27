defmodule StartupGame.Accounts.UserTest do
  use StartupGame.DataCase

  alias StartupGame.Accounts.User

  import StartupGame.AccountsFixtures

  describe "user visibility changeset" do
    test "visibility_changeset/2 with valid attributes" do
      user = user_fixture()
      changeset = User.visibility_changeset(user, %{default_game_visibility: :public})
      assert changeset.valid?
      assert get_change(changeset, :default_game_visibility) == :public
    end

    test "visibility_changeset/2 with invalid attributes" do
      user = user_fixture()
      changeset = User.visibility_changeset(user, %{default_game_visibility: :invalid})
      refute changeset.valid?
    end

    test "visibility_changeset/2 only allows valid visibility values" do
      user = user_fixture()
      changeset = User.visibility_changeset(user, %{default_game_visibility: :not_allowed})
      assert %{default_game_visibility: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "user registration changeset" do
    test "registration_changeset/3 sets default visibility to private when not specified" do
      valid_attrs = valid_user_attributes()
      changeset = User.registration_changeset(%User{}, valid_attrs)
      # uses schema default
      assert get_change(changeset, :default_game_visibility) == nil
    end

    test "registration_changeset/3 allows setting visibility" do
      valid_attrs = valid_user_attributes(%{default_game_visibility: :public})
      changeset = User.registration_changeset(%User{}, valid_attrs)
      assert get_change(changeset, :default_game_visibility) == :public
    end

    test "registration_changeset/3 validates visibility value" do
      invalid_attrs = valid_user_attributes(%{default_game_visibility: :invalid})
      changeset = User.registration_changeset(%User{}, invalid_attrs)
      assert %{default_game_visibility: ["is invalid"]} = errors_on(changeset)
    end
  end
end
