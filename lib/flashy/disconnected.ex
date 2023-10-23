defmodule Flashy.Disconnected do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      @spec new(Component.t()) :: Flashy.Disconnected.t()
      defdelegate new(component \\ Flashy.Component.new(&render/1)), to: Flashy.Disconnected
    end
  end

  alias Flashy.Helpers

  use Phoenix.Component

  use TypedStruct

  import PhxComponentHelpers

  typedstruct enforce: true do
    field :component, Flashy.Component.t()
  end

  @spec new(Component.t()) :: t
  def new(component), do: struct!(__MODULE__, component: component)

  attr :key, :string, required: true

  attr :class, :string, default: ""

  attr :rest, :global

  slot :inner_block

  def render(assigns) do
    assigns = extend_class(assigns, Helpers.notification_classes())

    ~H"""
    <div
      id={@key}
      {@heex_class}
      phx-hook="DisconnectedNotificationHook"
      data-hide={Helpers.hide_notification(@key)}
      data-show={Helpers.show_notification(@key)}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defimpl Flashy.Protocol, for: __MODULE__ do
    def module(notification), do: notification.component.module

    def function_name(notification), do: notification.component.function_name
  end
end
