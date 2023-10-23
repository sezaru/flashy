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

  attr :rest, :global

  slot :inner_block

  def render(assigns) do
    assigns = extend_class(assigns, Helpers.notification_classes())

    ~H"""
    <div
      id={@key}
      {@heex_class}
      phx-hook="FlashHook"
      phx-mounted={Helpers.show_notification(@key)}
      data-hide={Helpers.hide_notification(@key)}
      data-show={Helpers.show_notification(@key)}
      data-dismissible={"#{@notification.options.dismissible?}"}
      data-dismiss-time={@notification.options.dismiss_time}
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
