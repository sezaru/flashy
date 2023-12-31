defmodule Flashy do
  @moduledoc false

  alias Flashy.Notification

  alias Phoenix.{Controller, LiveView, LiveView.Socket}

  alias Plug.Conn

  @spec put_notification(Conn.t() | Socket.t(), Notification.Protocol.t()) :: Conn.t() | Socket.t()
  def put_notification(%Socket{} = socket, notification) do
    key = :erlang.unique_integer([:positive, :monotonic]) |> to_string() |> then(&"flashy-#{&1}")

    LiveView.put_flash(socket, key, notification)
  end

  def put_notification(%Conn{} = conn, notification) do
    key = :erlang.unique_integer([:positive, :monotonic]) |> to_string() |> then(&"flashy-#{&1}")

    Controller.put_flash(conn, key, notification)
  end

  @spec send_notification(Socket.t(), Notification.Protocol.t(), pid) :: Socket.t()
  def send_notification(%Socket{} = socket, notification, pid \\ self()) do
    send(pid, {:flashy_notification, notification})

    socket
  end
end
