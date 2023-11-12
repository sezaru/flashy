defmodule Flashy.Hook do
  @moduledoc false

  use Phoenix.Component

  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    socket = attach_hook(socket, :flashy, :handle_info, &handle_info/2)

    {:cont, socket}
  end

  defp handle_info({:flashy_notification, notification}, socket),
    do: {:halt, Flashy.put_notification(socket, notification)}

  defp handle_info(_, socket), do: {:cont, socket}
end
