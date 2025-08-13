defmodule Flashy.Normal do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      @type type ::
              unquote(
                opts
                |> Keyword.get(:types, [:info, :success, :warning, :danger])
                |> Enum.map(&inspect/1)
                |> Enum.join(" | ")
                |> Code.string_to_quoted!()
              )

      @spec new(type, String.t(), Flashy.Normal.Options.t(), Flashy.Component.t()) ::
              Flashy.Normal.t()
      defdelegate new(
                    type,
                    message,
                    options \\ Flashy.Normal.Options.new(),
                    component \\ Flashy.Component.new(&render/1)
                  ),
                  to: Flashy.Normal
    end
  end

  alias Flashy.{Helpers, Component, Normal.Options}

  alias Phoenix.LiveView.{JS, ColocatedHook}

  use Phoenix.Component

  use TypedStruct

  import PhxComponentHelpers

  typedstruct enforce: true do
    field :type, atom
    field :message, String.t()

    field :options, Options.t()

    field :component, Component.t()
  end

  @spec new(atom, String.t(), Options.t(), Component.t()) :: t
  def new(type, message, options, component),
    do: struct!(__MODULE__, type: type, message: message, options: options, component: component)

  attr :key, :string, required: true
  attr :notification, __MODULE__, required: true

  attr :class, :string, default: ""

  attr :hide_action, JS, default: nil
  attr :show_action, JS, default: nil

  attr :rest, :global

  slot :inner_block

  def render(assigns) do
    assigns = extend_class(assigns, Helpers.notification_classes())

    ~H"""
    <div
      id={@key}
      {@heex_class}
      phx-hook=".FlashHook"
      phx-mounted={@show_action || Helpers.show_notification(@key)}
      data-hide={@hide_action || Helpers.hide_notification(@key)}
      data-show={@show_action || Helpers.show_notification(@key)}
      data-dismissible={"#{@notification.options.dismissible?}"}
      data-dismiss-time={@notification.options.dismiss_time}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>

    <script :type={ColocatedHook} name=".FlashHook">
      const hide = (liveSocket, element) => liveSocket.execJS(element, element.dataset.hide)

      const updateProgress = (element, progress) => element.style.width = `${progress}%`

      export default {
        mounted() {
          this.isDismissible = this.el.dataset.dismissible === "true"

          if (!this.isDismissible) {
            return
          }

          this.progressElement = this.el.querySelector(`#${this.el.id}-progress`)

          const dismissTime = parseInt(this.el.dataset.dismissTime)
          const progressTimeout = dismissTime / 100

          this.counter = 0

          const updateCounter = () => {
            this.counter++

            updateProgress(this.progressElement, this.counter)

            if (this.counter == 100) {
              clearTimeout(this.timer)

              hide(this.liveSocket, this.el)
            } else {
              this.timer = setTimeout(updateCounter, progressTimeout)
            }
          }

          this.timer = setTimeout(updateCounter, progressTimeout)

          this.handleHideStart = () => {
            clearTimeout(this.timer)
          }

          this.handleMouseEnter = () => {
            clearTimeout(this.timer)

            this.counter = 0

            updateProgress(this.progressElement, this.counter)
          }

          this.handleMouseLeave = () => {
            this.timer = setTimeout(updateCounter, progressTimeout)
          }

          this.el.addEventListener("phx:hide-start", this.handleHideStart)
          this.el.addEventListener("mouseenter", this.handleMouseEnter)
          this.el.addEventListener("mouseleave", this.handleMouseLeave)
        },

        updated() {
          if (this.isDismissible) {
            updateProgress(this.progressElement, this.counter)
          }
        },

        destroyed() {
          this.el.removeEventListener("mouseleave", this.handleMouseLeave)
          this.el.removeEventListener("mouseenter", this.handleMouseEnter)
          this.el.removeEventListener("phx:hide-start", this.handleHideStart)

          if (!this.isDismissible) {
            return
          }

          clearTimeout(this.timer)
        }
      }
    </script>
    """
  end

  defimpl Flashy.Protocol, for: __MODULE__ do
    def module(notification), do: notification.component.module

    def function_name(notification), do: notification.component.function_name
  end
end
