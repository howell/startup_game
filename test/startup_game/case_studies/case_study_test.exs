defmodule StartupGame.CaseStudies.CaseStudyTest do
  use StartupGame.DataCase, async: true

  alias StartupGame.CaseStudies.CaseStudy
  alias StartupGame.CaseStudies.Theranos
  alias StartupGame.Accounts
  alias StartupGame.Games
  alias StartupGame.Repo

  def game_exists?(id), do: Repo.exists?(from g in Games.Game, where: g.id == ^id)

  describe "CaseStudy functions" do
    setup do
      theranos_data = Theranos.case_study()
      %{theranos_data: theranos_data}
    end

    test "create/1 creates a user, game, and rounds", %{theranos_data: theranos_data} do
      assert {:ok, %Games.Game{} = game} = CaseStudy.create(theranos_data)

      # Verify user creation
      user = Accounts.get_user_by_username(theranos_data.user.name)
      refute is_nil(user)
      assert user.username == theranos_data.user.name

      # Verify game creation
      assert game.name == theranos_data.company
      assert game.description == theranos_data.description
      assert game.user_id == user.id
      assert game.status == :completed
      assert game.exit_type == theranos_data.exit_type
      assert Decimal.equal?(game.exit_value, theranos_data.exit_value)

      # Verify round creation
      rounds = Games.list_game_rounds(game.id)
      assert length(rounds) == length(theranos_data.rounds)
    end

    test "delete/1 deletes the user and associated data", %{theranos_data: theranos_data} do
      # First, create the case study
      assert {:ok, game} = CaseStudy.create(theranos_data)
      user = Accounts.get_user_by_username(theranos_data.user.name)
      refute is_nil(user)
      assert game_exists?(game.id)

      # Now delete it
      assert {:ok, %Accounts.User{}} = CaseStudy.delete(theranos_data)

      # Verify deletion
      assert is_nil(Accounts.get_user_by_username(theranos_data.user.name))
      assert not game_exists?(game.id)
      assert Repo.all(from g in Games.Game, where: g.user_id == ^user.id) == []
    end

    test "create_or_replace/1 creates data if it doesn't exist", %{
      theranos_data: theranos_data
    } do
      assert {:ok, %Games.Game{}} = CaseStudy.create_or_replace(theranos_data)

      user = Accounts.get_user_by_username(theranos_data.user.name)
      refute is_nil(user)

      assert Repo.exists?(
               from g in Games.Game,
                 where: g.user_id == ^user.id,
                 where: g.name == ^theranos_data.company
             )
    end

    test "create_or_replace/1 replaces data if it exists", %{theranos_data: theranos_data} do
      # Create initial data
      {:ok, initial_game} = CaseStudy.create_or_replace(theranos_data)
      initial_user = Accounts.get_user_by_username(theranos_data.user.name)
      refute is_nil(initial_user)
      assert initial_game.user_id == initial_user.id

      # Create/Replace again
      assert {:ok, new_game} = CaseStudy.create_or_replace(theranos_data)
      # Should be the same username, but potentially different ID
      new_user = Accounts.get_user_by_username(theranos_data.user.name)

      # Check that the old game associated with the potentially old user is gone
      # Note: Repo.delete cascades, so the old user and game should be gone.
      refute game_exists?(initial_game.id)

      # Verify the new user and game exist
      refute is_nil(new_user)
      assert new_game.user_id == new_user.id
      assert new_game.name == theranos_data.company

      # Ensure only one game exists for this username (via the new user)
      user_games = Repo.all(from g in Games.Game, where: g.user_id == ^new_user.id)
      assert length(user_games) == 1
      assert hd(user_games).id == new_game.id
    end
  end
end
