defmodule StartupGameWeb.GameLive.Components.GameCreationComponent do
  @moduledoc """
  Component for rendering the game creation interface where users can input company name and description.
  """
  use StartupGameWeb, :html
  alias StartupGameWeb.GameLive.Components.Shared.ChatHistory
  alias StartupGameWeb.GameLive.Components.Shared.ResponseForm
  alias StartupGameWeb.GameLive.Components.Shared.ProviderSelector
  alias StartupGameWeb.GameLive.Components.Shared.GameLayoutComponent

  @doc """
  Renders the game creation interface for collecting company name and description.
  """
  attr :creation_stage, :atom, required: true
  attr :temp_name, :string, default: nil
  attr :rounds, :list, required: true
  attr :response, :string, default: ""
  attr :provider_preference, :atom, required: true
  attr :streaming, :boolean, default: false
  attr :partial_content, :string, default: ""
  attr :streaming_type, :atom, default: nil
  attr :is_mobile_state_visible, :boolean, default: false

  def game_creation(assigns) do
    ~H"""
    <GameLayoutComponent.game_layout is_mobile_state_visible={@is_mobile_state_visible}>
      <:state_panel>
        <.creation_state_panel
          creation_stage={@creation_stage}
          temp_name={@temp_name}
          provider_preference={@provider_preference}
          include_provider_selector={true}
        />
      </:state_panel>

      <:mobile_state_panel>
        <.creation_state_panel
          creation_stage={@creation_stage}
          temp_name={@temp_name}
          provider_preference={@provider_preference}
          include_provider_selector={false}
        />
      </:mobile_state_panel>

      <:content_area>
        <div class="h-full flex flex-col">
          <div class="flex-1 overflow-y-auto" id="chat-messages" phx-hook="ScrollToBottom">
            <ChatHistory.chat_history
              rounds={@rounds}
              streaming={@streaming}
              streaming_type={@streaming_type}
              partial_content={@partial_content}
            />
          </div>

          <div class="mt-4 p-4 border-t">
            <div class="mx-auto w-full">
              <ResponseForm.response_form
                placeholder={
                  if @creation_stage == :name_input,
                    do: "Enter your company name",
                    else: "Describe what your company does"
                }
                value={@response}
                disabled={@streaming}
              />
            </div>
          </div>
        </div>
      </:content_area>
    </GameLayoutComponent.game_layout>
    """
  end

  attr :creation_stage, :atom, required: true
  attr :temp_name, :string, default: nil
  attr :provider_preference, :atom, required: true
  attr :include_provider_selector, :boolean, default: false

  defp creation_state_panel(assigns) do
    ~H"""
    <div class="h-full overflow-y-auto p-5">
      <div class="mb-6">
        <h2 class="heading-md mb-1">New Startup Venture</h2>
        <p class="text-foreground/70 text-sm mb-2">
          Let's get started with your new company
        </p>
      </div>

      <div class="space-y-6">
        <div class="bg-white rounded-lg shadow-md p-4 mb-4">
          <h2 class="text-lg font-semibold mb-3">Getting Started</h2>
          <div class="space-y-4">
            <p class="text-gray-600">
              <%= if @creation_stage == :name_input do %>
                First, let's give your startup a name. What would you like to call your company?
              <% else %>
                Now, tell us what {@temp_name} does. Provide a brief description of your startup's mission and product.
              <% end %>
            </p>
          </div>
        </div>

        <%= if @include_provider_selector do %>
          <ProviderSelector.provider_selector
            provider_preference={@provider_preference}
            creation_mode={true}
          />
        <% end %>

        <div class="bg-white rounded-lg shadow-md p-4">
          <h2 class="text-lg font-semibold mb-3">Startup Journey</h2>
          <div class="space-y-2">
            <p class="text-gray-600">
              After setting up your company, you'll navigate challenges, make strategic decisions, and try to grow your startup to success.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
