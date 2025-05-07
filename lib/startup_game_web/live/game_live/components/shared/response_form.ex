defmodule StartupGameWeb.GameLive.Components.Shared.ResponseForm do
  @moduledoc """
  Component for rendering a response input form with customizable placeholder and button text.
  """
  use StartupGameWeb, :html
  alias StartupGameWeb.GameLive.Components.Shared.Tooltips

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
  attr :player_mode, :atom, default: :responding
  attr :show_mode_buttons, :boolean, default: true

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
      <div class="mt-2 text-xs text-foreground/60 relative">
        <span class="absolute left-0 top-1/2 -translate-y-1/2">Press Enter to send</span>
        <!-- Mode Switching Buttons -->
        <div :if={@show_mode_buttons} class="flex justify-center space-x-3 text-xs">
          <form>
            <button
              :if={@player_mode == :responding}
              type="button"
              phx-click="switch_player_mode"
              phx-value-player_mode="acting"
              class="silly-button-secondary px-3 py-1"
              disabled={@disabled}
            >
              Take the Wheel!<Tooltips.take_the_wheel id="chat-take-the-wheel-tooltip" />
            </button>
            <button
              :if={@player_mode == :acting}
              type="button"
              phx-click="switch_player_mode"
              phx-value-player_mode="responding"
              class="silly-button-secondary px-3 py-1"
              disabled={@disabled}
            >
              Bezos Take the Wheel!<Tooltips.release_the_wheel id="chat-release-the-wheel-tooltip" />
            </button>
          </form>
        </div>
      </div>
    </form>
    """
  end
end
