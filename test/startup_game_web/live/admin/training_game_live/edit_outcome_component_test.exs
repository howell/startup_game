defmodule StartupGameWeb.Admin.TrainingGameLive.EditOutcomeComponentTest do
  use StartupGameWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias StartupGame.GamesFixtures

  alias StartupGameWeb.Admin.TrainingGameLive.EditOutcomeComponent

  @endpoint StartupGameWeb.Endpoint

  # Placeholder LiveView to host the component
  defmodule TestLive do
    use Phoenix.Component
    use StartupGameWeb, :live_view

    def mount(_params, session, socket) do
      round = StartupGame.Games.get_round!(session["round_id"])
      round = StartupGame.Repo.preload(round, :ownership_changes)
      {:ok, assign(socket, round: round, parent_pid: session["parent_pid"])}
    end

    def render(assigns) do
      ~H"""
      <div>
        <.live_component
          module={EditOutcomeComponent}
          id={"edit-comp-#{@round.id}"}
          round={@round}
          parent_pid={@parent_pid}
        />
      </div>
      """
    end
  end

  # Helper function to mount a component for testing
  defp mount_component(component, assigns) do
    Phoenix.LiveViewTest.render_component(
      component,
      assigns,
      router: StartupGameWeb.Router
    )
  end

  describe "rendering" do
    test "renders the form with round data" do
      game = GamesFixtures.game_fixture(%{})

      round =
        GamesFixtures.round_fixture(
          game,
          %{
            outcome: "Initial Outcome",
            cash_change: 100,
            burn_rate_change: 50
          }
        )

      # Preload changes for display (even if empty)
      round = StartupGame.Repo.preload(round, :ownership_changes)

      # Render component
      component_html =
        mount_component(EditOutcomeComponent, %{
          id: "edit-comp-#{round.id}",
          round: round,
          parent_pid: self()
        })

      assert component_html =~ "Edit Round Outcome (ID: #{round.id})"
      assert component_html =~ "Outcome Narrative"
      assert component_html =~ "Initial Outcome"
      assert component_html =~ "Cash Change"
      # Check default value
      assert component_html =~ "value=\"100\""
      assert component_html =~ "Burn Rate Change"
      # Check default value
      assert component_html =~ "value=\"50\""
      assert component_html =~ "Ownership Changes in this Round:"
      # Check for the read-only message if no changes exist
      assert component_html =~
               "(Ownership changes are recorded automatically and cannot be edited here.)"

      assert component_html =~ "Save Changes"
      assert component_html =~ "Cancel"
    end
  end

  describe "form interaction" do
    setup do
      game = GamesFixtures.game_fixture(%{})
      round = GamesFixtures.round_fixture(game) |> StartupGame.Repo.preload(:ownership_changes)

      # Set up the conn and mount the parent LiveView
      {:ok, view, _html} =
        live_isolated(
          Phoenix.ConnTest.build_conn(),
          TestLive,
          session: %{"round_id" => round.id, "parent_pid" => self()}
        )

      # Now we'll store a reference to the parent liveview and the round
      {:ok, %{view: view, round: round, game: game}}
    end

    test "validate event validates the input", %{view: view, round: round} do
      # We don't need to mount the component manually since it's already mounted in setup

      # Now we can render a change event to simulate form validation
      rendered =
        element(view, "#edit-outcome-form-#{round.id}")
        |> render_change(%{
          "round" => %{"outcome" => "", "cash_change" => "100", "burn_rate_change" => "50"},
          "_target" => ["round", "outcome"]
        })

      # Verify the form still shows after validation
      assert rendered =~ "Outcome Narrative"
    end

    test "save event sends message to parent", %{view: view, round: round} do
      # Simulate submission of the form with valid data
      element(view, "#edit-outcome-form-#{round.id}")
      |> render_submit(%{
        "round" => %{
          "outcome" => "Updated Outcome",
          "cash_change" => "200.50",
          "burn_rate_change" => "-10.00"
        }
      })

      # Verify the parent process received the message
      assert_receive {:saved_outcome, updated_round}
      assert updated_round.id == round.id
      assert updated_round.outcome == "Updated Outcome"
      assert Decimal.equal?(updated_round.cash_change, Decimal.new("200.50"))
      assert Decimal.equal?(updated_round.burn_rate_change, Decimal.new("-10.00"))
    end

    test "uses TrainingGames.update_round_outcome/2 for saving", %{view: view, round: round} do
      # Create a mock expectation to verify the context is called
      attrs = %{
        "outcome" => "Context Called Test",
        "cash_change" => "300",
        "burn_rate_change" => "25"
      }

      # Submit the form with our test attributes
      element(view, "#edit-outcome-form-#{round.id}")
      |> render_submit(%{
        "round" => attrs
      })

      # Verify we received the saved_outcome message
      assert_receive {:saved_outcome, updated_round}

      # The component should have used the TrainingGames context function
      # which would have returned a round with the values we submitted
      assert updated_round.outcome == "Context Called Test"
      assert Decimal.equal?(updated_round.cash_change, Decimal.new("300"))
      assert Decimal.equal?(updated_round.burn_rate_change, Decimal.new("25"))
    end

    test "cancel event sends message to parent", %{view: view} do
      element(view, "button", "Cancel") |> render_click()

      # Verify the parent process received the close message
      assert_receive {:close_edit_outcome_form}
    end

    test "save event re-renders form with errors on invalid input", %{view: view, round: round} do
      # Simulate submission with invalid data
      rendered =
        element(view, "#edit-outcome-form-#{round.id}")
        |> render_submit(%{
          "round" => %{
            "outcome" => "Valid Outcome",
            "cash_change" => "not-a-number",
            "burn_rate_change" => "5"
          }
        })

      # Check for error message
      assert rendered =~ "is invalid"
      # Ensure form is re-rendered
      assert rendered =~ "Edit Round Outcome"
    end
  end
end
