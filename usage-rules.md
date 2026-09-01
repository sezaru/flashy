# Flashy usage rules

Flashy extends LiveView's flash to function and live components — rich, replaceable,
component-rendered notifications instead of plain `put_flash` strings.

## Use Flashy instead of `put_flash`

In a project that depends on `flashy`, do **not** use `Phoenix.LiveView.put_flash/3` or
`Phoenix.Controller.put_flash/3` for notifications. Use:

- `Flashy.put_notification(socket_or_conn, notification, opts \\ [])` — add a notification to
  the flash. Accepts a `Phoenix.LiveView.Socket` or a `Plug.Conn`.
- `Flashy.send_notification(socket, notification, opts \\ [])` — send a notification to the
  parent LiveView (use from a component/child). `opts[:pid]` defaults to `self()`.

`opts[:key]` is optional and defaults to a random key. Pass an explicit `:key` **only** when
you want to REPLACE an existing notification rather than add a new one.

## Building a notification

A notification is a `Flashy.Protocol` struct produced by one of your app's notification
modules (built on Flashy's `Normal`). Define them once, then:

```elixir
alias MyAppWeb.Components.Notifications.Normal

socket
|> Flashy.put_notification(Normal.new(:info, "Saved"))
```

Because notifications render as components, HTML in the message body is supported.

## Setup

Render Flashy's container in your layout and wire its JS hook as described in the README
(`priv/static/flashy.min.js`). Without the container mounted, notifications won't display.
