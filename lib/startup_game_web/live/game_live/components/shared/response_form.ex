defmodule StartupGameWeb.GameLive.Components.Shared.ResponseForm do
  @moduledoc """
  Component for rendering a response input form with customizable placeholder and button text.
  """
  use Phoenix.Component

  @doc """
  Renders a response input form.

  ## Examples

      <.response_form
        placeholder="Enter your response"
        button_text="Send"
        value={@response}
        submit_event="submit_response"
      />

  """
  attr :placeholder, :string, required: true
  attr :button_text, :string, required: true
  attr :value, :string, default: ""
  attr :submit_event, :string, default: "submit_response"

  def response_form(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-md p-4">
      <form phx-submit={@submit_event}>
        <textarea
          name="response"
          placeholder={@placeholder}
          class="w-full p-3 border rounded-md mb-3"
          rows="3"
          value={@value}
          required
        ></textarea>
        <button
          type="submit"
          class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded w-full"
        >
          <%= @button_text %>
        </button>
      </form>
    </div>
    """
  end
end
