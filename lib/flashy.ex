defmodule Flashy do
  @moduledoc false

  alias Flashy.Notification

  alias Phoenix.{LiveView, LiveView.Socket}

  @spec put_notification(Socket.t(), Notification.Protocol.t()) :: Socket.t()
  def put_notification(socket, notification) do
    key = :erlang.unique_integer([:positive, :monotonic]) |> to_string() |> then(&"flashy-#{&1}")

    LiveView.put_flash(socket, key, notification)
  end

  @spec send_notification(Socket.t(), Notification.Protocol.t(), pid) :: Socket.t()
  def send_notification(%Socket{} = socket, notification, pid \\ self()) do
    send(pid, {:flashy_notification, notification})

    socket
  end
end
