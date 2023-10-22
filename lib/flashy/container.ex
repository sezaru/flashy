defmodule Flashy.Container do
  @moduledoc false

  alias Flashy.Protocol

  use Phoenix.Component

  attr :flash, :map, required: true

  def render(assigns) do
    disconnected_notification = Application.fetch_env!(:flashy, :disconnected_module).new()

    assigns = Map.put(assigns, :disconnected_notification, disconnected_notification)

    ~H"""
    <div class="pointer-events-none fixed py-3 flex flex-col gap-3 z-100 items-end max-h-screen right-0 top-0">
      <.render_notification key="disconnected" notification={@disconnected_notification} />

      <.render_notification
        :for={{key, notification} <- Enum.sort_by(@flash, fn {key, _} -> key end)}
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
end
