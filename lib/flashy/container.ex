defmodule Flashy.Container do
  @moduledoc false

  alias Flashy.Protocol

  use Phoenix.Component

  import PhxComponentHelpers

  attr :flash, :map, required: true

  attr :class, :string, default: ""

  attr :rest, :global

  def render(assigns) do
    disconnected_notification = Application.fetch_env!(:flashy, :disconnected_module).new()

    assigns =
      assigns
      |> Map.put(:disconnected_notification, disconnected_notification)
      |> extend_class(
        "pointer-events-none fixed py-3 flex flex-col gap-3 z-100 items-end max-h-screen right-0 top-0"
      )

    ~H"""
    <div {@heex_class} {@rest}>
      <.render_notification key="disconnected" notification={@disconnected_notification} />

      <.render_notification
        :for={{key, notification} <- Enum.sort_by(@flash, &sort_by_key/1)}
        key={key}
        notification={notification}
      />
    </div>
    """
  end

  attr :key, :string, required: true
  attr :notification, :any, required: true

  attr :rest, :global

  defp render_notification(assigns) do
    ~H"""
    <%= apply(Protocol.module(@notification), Protocol.function_name(@notification), [assigns]) %>
    """
  end

  defp sort_by_key({"flashy-custom-" <> key, _}), do: key
  defp sort_by_key({"flashy-" <> key, _}), do: String.to_integer(key)
end
