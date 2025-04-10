defmodule StartupGameWeb.GameLive.Components.Shared.ResponseForm do
  @moduledoc """
  Component for rendering a response input form with customizable placeholder and button text.
  """
  use StartupGameWeb, :html

  @doc """
  Renders a response input form.

  ## Examples

      <.response_form
        placeholder="Enter your response"
        value={@response}
        submit_event="submit_response"
      />

  """
  attr :placeholder, :string, required: true
  attr :value, :string, default: ""
  attr :submit_event, :string, default: "submit_response"
  attr :disabled, :boolean, default: false

  def response_form(assigns) do
    ~H"""
    <form phx-submit={@submit_event} class="w-full">
      <div class="flex gap-2">
        <textarea
          id="response-textarea"
          name="response"
          placeholder={@placeholder}
          class="flex-1 resize-none p-3 rounded-lg border-gray-200 focus:border-silly-blue focus:ring-silly-blue/20"
          rows="2"
          value={@value}
          required
          disabled={@disabled}
          phx-hook="TextareaSubmit"
        ></textarea>
        <div class="flex flex-col justify-center">
          <button
            type="submit"
            class={[
              "silly-button-primary flex items-center justify-center",
              @disabled && "opacity-60 cursor-not-allowed"
            ]}
            disabled={@disabled}
          >
            <.icon name="hero-paper-airplane" class="h-5 w-5" />
          </button>
        </div>
      </div>
      <div class="mt-2 text-xs text-foreground/60">
        <span>Press Enter to send</span>
      </div>
    </form>
    """
  end
end
