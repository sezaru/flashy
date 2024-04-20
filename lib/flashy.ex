defmodule Flashy do
  @moduledoc false

  alias Phoenix.{Controller, LiveView, LiveView.Socket}

  alias Plug.Conn

  @doc """
  Put notification to LiveView flash.

  ## Options

    * `:key` - The optional notification flash key.
      Defaults to a random number.

      Only use this if you need to replace a notification instead of adding a new one.
  """
  @spec put_notification(Conn.t() | Socket.t(), Flashy.Protocol.t(), Keyword.t()) ::
          Conn.t() | Socket.t()
  def put_notification(socket_or_conn, notification, opts \\ [])

  def put_notification(%Socket{} = socket, notification, opts) do
    key = calculate_key(opts[:key])

    LiveView.put_flash(socket, key, notification)
  end

  def put_notification(%Conn{} = conn, notification, opts) do
    key = calculate_key(opts[:key])

    Controller.put_flash(conn, key, notification)
  end

  @doc """
  Send a notification to the parent LiveView.

  ## Options

    * `:key` - The optional notification flash key.
      Defaults to a random number.

      Only use this if you need to replace a notification instead of adding a new one.

    * `:pid` - The optional pid of the target LiveView.
      Defaults to `self/0`.
  """
  @spec send_notification(Socket.t(), Flashy.Protocol.t(), Keyword.t()) :: Socket.t()
  def send_notification(%Socket{} = socket, notification, opts \\ []) do
    pid = opts[:pid] || self()

    send(pid, {:flashy_notification, notification, opts})

    socket
  end

  defp calculate_key(nil) do
    :erlang.unique_integer([:positive, :monotonic]) |> to_string() |> then(&"flashy-#{&1}")
  end

  defp calculate_key(key) when is_binary(key), do: "flashy-custom-#{key}"
end
