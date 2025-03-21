defmodule StartupGameWeb.GameLive.Components.GameCreationComponent do
  @moduledoc """
  Component for rendering the game creation interface where users can input company name and description.
  """
  use StartupGameWeb, :html
  alias StartupGameWeb.GameLive.Components.Shared.ChatHistory
  alias StartupGameWeb.GameLive.Components.Shared.ResponseForm
  alias StartupGameWeb.GameLive.Components.Shared.ProviderSelector

  @doc """
  Renders the game creation interface for collecting company name and description.
  """
  attr :creation_stage, :atom, required: true
  attr :temp_name, :string, default: nil
  attr :rounds, :list, required: true
  attr :response, :string, default: ""
  attr :provider_preference, :string, default: "StartupGame.Engine.LLMScenarioProvider"

  def game_creation(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row gap-6">
      <!-- Chat area -->
      <div class="flex-grow order-2 md:order-1">
        <div class="bg-white rounded-lg shadow-md p-4 mb-4">
          <h1 class="text-2xl font-bold">New Startup Venture</h1>
          <p class="text-gray-600">Let's get started with your new company</p>
        </div>

        <ChatHistory.chat_history rounds={@rounds} />

        <ResponseForm.response_form
          placeholder={
            if @creation_stage == :name_input,
              do: "Enter your company name",
              else: "Describe what your company does"
          }
          button_text={
            if @creation_stage == :name_input,
              do: "Set Company Name",
              else: "Set Company Description"
          }
          value={@response}
        />
      </div>
      
    <!-- Info panel -->
      <div class="w-full md:w-80 order-1 md:order-2">
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

        <ProviderSelector.provider_selector
          provider_preference={@provider_preference}
          creation_mode={true}
        />

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
