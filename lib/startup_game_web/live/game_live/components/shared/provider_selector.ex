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
      <div>
        <h3 class="text-sm font-semibold text-foreground/70 mb-3">DEVELOPER OPTIONS</h3>
        <form phx-submit={if @creation_mode, do: "set_provider", else: "change_provider"} class="space-y-2">
          <div>
            <label class="text-sm text-foreground/70 block mb-1">Scenario Provider:</label>
            <select name="provider" class="w-full rounded-lg border-gray-200 text-sm focus:border-silly-blue focus:ring-silly-blue/20">
              <%= for option <- @provider_options do %>
                <.provider_option
                  value={option.value}
                  label={option.label}
                  provider_preference={@provider_preference || (@game && @game.provider_preference)}
                />
              <% end %>
            </select>
          </div>
          <button
            type="submit"
            class="silly-button-secondary w-full text-sm"
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
