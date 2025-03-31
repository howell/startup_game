defmodule StartupGame.CaseStudies.CaseStudy do
  @moduledoc """
  A case study is a fabricated instance of a user/game
  """
  alias StartupGame.Games.{Game, Round}
  alias StartupGame.Games
  alias StartupGame.Accounts
  alias StartupGame.Accounts.User
  alias StartupGame.Engine.Demo.StaticScenarioProvider
  alias StartupGame.Repo
  require Logger

  @type t() :: %{
          user: user_spec(),
          company: String.t(),
          description: String.t(),
          rounds: [round()],
          status: Game.status(),
          exit_type: Game.exit_type(),
          exit_value: Decimal.t(),
          founder_return: Decimal.t()
        }

  @type user_spec() :: %{
          name: String.t()
        }

  @type round() :: %{
          situation: String.t(),
          response: String.t(),
          outcome: String.t()
        }

  @doc """
  Create a case study and the corresponding user.
  If the user already exists, delete it and any of their associated games and case studies.
  """
  @spec create_or_replace(t()) :: {:ok, Game.t()} | {:error, String.t()}
  def create_or_replace(case_study) do
    Logger.info("Creating or replacing case study for #{case_study.user.name}")

    case delete(case_study) do
      {:ok, _} ->
        Logger.info("Deleted existing user and associated games and case studies")

      {:error, error} ->
        Logger.info(
          "Error deleting existing user and associated games and case studies: #{inspect(error)}"
        )
    end

    case create(case_study) do
      {:ok, game} ->
        Logger.info("Created case study for #{case_study.user.name}")
        {:ok, game}

      {:error, error} ->
        Logger.error("Error creating case study for #{case_study.user.name}: #{inspect(error)}")
        {:error, error}
    end
  end

  @doc """
  Save a case study to the database
  """
  @spec create(t()) :: {:ok, Game.t()} | {:error, String.t()}
  def create(case_study) do
    with {:ok, user} <- save_user(case_study.user),
         {:ok, game} <- save_game(user, case_study),
         {:ok, _} <- save_rounds(game, case_study.rounds),
         {:ok, game} <- Games.complete_game(game, case_study.exit_type, case_study.exit_value) do
      {:ok, game}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Delete a case study from the database
  """
  @spec delete(t()) :: {:ok, any()} | {:error, String.t()}
  def delete(case_study) do
    case_study
    |> get_in([:user, :name])
    |> Accounts.get_user_by_username()
    |> case do
      nil ->
        {:ok, :not_found}

      user ->
        Repo.delete(user)
    end
  end

  @spec save_user(user_spec()) :: {:ok, User.t()} | {:error, String.t()}
  defp save_user(user) do
    Accounts.register_user(%{
      username: user.name,
      email: "samcaldwell19+#{user.name}@gmail.com",
      default_game_visibility: :public,
      password: generate_password()
    })
  end

  defp generate_password do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end

  @spec save_game(User.t(), t()) :: {:ok, Game.t()} | {:error, String.t()}
  defp save_game(user, case_study) do
    Games.create_new_game(
      %{
        name: case_study.company,
        description: case_study.description,
        user: user,
        provider: StaticScenarioProvider,
        cash_on_hand: Decimal.new("10000000"),
        burn_rate: Decimal.new("1000000"),
        exit_value: Decimal.new("0"),
        founder_return: Decimal.new("0"),
        is_case_study: true
      },
      user
    )
  end

  @spec save_rounds(Game.t(), [round()]) :: {:ok, [Round.t()]} | {:error, String.t()}
  defp save_rounds(game, rounds) do
    Enum.reduce_while(rounds, {:ok, []}, fn round, {:ok, acc} ->
      case Games.create_game_round(round, game) do
        {:ok, round} ->
          {:cont, {:ok, [round | acc]}}

        {:error, error} ->
          {:halt, {:error, error}}
      end
    end)
  end
end
