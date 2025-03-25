defmodule StartupGameWeb.GameLive.Components.Shared.ProviderSelector do
  @moduledoc """
  Component for selecting the scenario provider.
  This component is shared between GamePlayComponent and GameCreationComponent.
  """
  use StartupGameWeb, :html

  @doc """
  Renders a form for selecting the scenario provider.
  Only shown in non-production environments.

  For existing games, pass the game object.
  For game creation, pass provider_preference as a string.
  """
  attr :game, :map, default: nil
  attr :provider_preference, :atom, default: nil
  attr :creation_mode, :boolean, default: false

  attr :provider_options, :list,
    default: [
      %{
        value: StartupGame.Engine.LLMScenarioProvider,
        label: "LLM Scenario Provider"
      },
      %{
        value: StartupGame.Engine.Demo.StaticScenarioProvider,
        label: "Static Scenario Provider"
      }
    ]

  def provider_selector(assigns) do
    ~H"""
    <%= if Application.get_env(:startup_game, :env, :prod) != :prod do %>
      <div class="bg-white rounded-lg shadow-md p-4 mb-4">
        <h2 class="text-lg font-semibold mb-3">Development Options</h2>
        <form phx-submit={if @creation_mode, do: "set_provider", else: "change_provider"}>
          <label class="block mb-2">Scenario Provider:</label>
          <select name="provider" class="block w-full rounded border-gray-300 mb-2">
            <%= for option <- @provider_options do %>
              <.provider_option
                value={option.value}
                label={option.label}
                provider_preference={@provider_preference || (@game && @game.provider_preference)}
              />
            <% end %>
          </select>
          <button
            type="submit"
            class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          >
            {if @creation_mode, do: "Set Provider", else: "Change Provider"}
          </button>
        </form>
      </div>
    <% end %>
    """
  end

  attr :value, :atom, required: true
  attr :label, :string, required: true
  attr :provider_preference, :any, default: nil
  # provider_preference is any because it can be an atom or a string

  defp provider_option(assigns) do
    ~H"""
    <option value={@value} selected={to_string(@provider_preference) == to_string(@value)}>
      {@label}
    </option>
    """
  end
end
