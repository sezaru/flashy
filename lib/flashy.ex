defmodule Flashy do
  @moduledoc false

  alias Phoenix.{Controller, LiveView, LiveView.Socket}

  alias Plug.Conn

  def put_notification(%Socket{} = socket, notification) do
    key = :erlang.unique_integer([:positive, :monotonic]) |> to_string() |> then(&"flashy-#{&1}")
  @spec put_notification(Conn.t() | Socket.t(), Flashy.Protocol.t()) :: Conn.t() | Socket.t()

    LiveView.put_flash(socket, key, notification)
  end

  def put_notification(%Conn{} = conn, notification) do
    key = :erlang.unique_integer([:positive, :monotonic]) |> to_string() |> then(&"flashy-#{&1}")

    Controller.put_flash(conn, key, notification)
  end

  def send_notification(%Socket{} = socket, notification, pid \\ self()) do
    send(pid, {:flashy_notification, notification})
  @spec send_notification(Socket.t(), Flashy.Protocol.t(), pid) :: Socket.t()

    socket
  end
end
