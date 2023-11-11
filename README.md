# Flashy

[![Hex](https://img.shields.io/hexpm/v/flashy.svg)](https://hex.pm/packages/flashy)
[![Hexdocs](https://img.shields.io/badge/-docs-green)](https://hexdocs.pm/flashy)

Flashy is a small library that extends LiveView's flash support to function and live components.

[2023-10-22 20-43-38.webm](https://github.com/sezaru/flashy/assets/279828/ac1784ab-1126-4625-8097-81d8fc40adb1)

## Installation

First add `Flashy` to your list of dependencies in `mix.exs`:

``` elixir
def deps do
  [
    {:flashy, "~> 0.2.3"}
  ]
end
```

Now, inside `assets/js/app.js`, add `flashy` hooks:

``` javascript
import FlashyHooks from "flashy"

// if you don't have any other hooks:
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: FlashyHooks})

// if you have other hooks:
const hooks = {
    MyHook: {
        // ...
    },
    ...FlashyHooks
}

let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks})
```

Now, inside `assets/tailwind.config.js`:

``` javascript
...

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/flashy_example_web.ex",
    "../lib/flashy_example_web/**/*.*ex",
    "../deps/flashy/**/*.*ex", // <-- Add this line
  ],
...
```

Now go to your web file `lib/<your_app>_web.ex` and add the following to `html_helpers` function:

``` elixir
  defp html_helpers do
    quote do
      ...

      # Add Flash notifications functionality
      import Flashy
    end
  end
```

Finally, you need to update your `lib/<your_app>_web/components/layouts/app.html.heex`:

Replace the line:

``` elixir
<.flash_group flash={@flash} />
```

With:

``` elixir
<Flashy.Container.render flash={@flash} />
```

### Flashy notification hook

`Flashy` also has a hook that can be added to `LiveViews` to make it easier to send notifications from a `LiveComponent` to a `LiveView` when no navigation is happening.

First, we need to add the hook to a `LiveView` `live_session`:

``` elixir
live_session :my_session, on_mount: [Flashy.Hook] do
  ...
end
```

Now, inside any `LiveComponent`, we can send a notification to the `LiveView` like this:

``` elixir
notification = Notification.Normal.new(:success, "some notification")

socket = send_notification(socket, notification)
```

### Using with controllers

If you want to also use `Flashy` with controllers outside `LiveView`, first you need to go to your web file `lib/<your_app>_web.ex` and add the following to `controller` function:

``` elixir
defp controller do
  quote do
    ...

    # Add Flash notifications functionality
    import Flashy
  end
end
```

Now, inside any `Controller`, we can send a notification like this:

``` elixir
def index(conn, _) do
  notification = Notifications.Normal.new(:info, "some notification")

  conn |> put_notification(notification) |> render(:index)
end
```

### Disconnected notifications

Now we need to, at least, implement the disconnected notification. `Flashy` doesn't come with any pre-defined disconnected notification design, so you need to implement it yourself.

Here is an example of one implementation using `PetalComponents` `alert` component:

``` elixir
defmodule MyProjectWeb.Components.Notifications.Disconnected do
  @moduledoc false

  use MyProjectWeb, :html

  use Flashy.Disconnected

  import PetalComponents.Alert

  attr :key, :string, required: true

  def render(assigns) do
    ~H"""
    <Flashy.Disconnected.render key={@key}>
      <.alert with_icon color="danger" heading="We can't find the internet">
        Attempting to reconnect <Heroicons.arrow_path class="ml-1 w-3 h-3 inline animate-spin" />
      </.alert>
    </Flashy.Disconnected.render>
    """
  end
end
```

Now you need to set the following config so `Flashy` knows what disconnected component we should use, to do that, in your `config/config.exs` add the following:

``` elixir
config :flashy,
  disconnected_module: MyProjectWeb.Components.Notifications.Disconnected
```

Now we are all set, `Flashy` is ready to be used.

## Adding normal notifications

Above we setup a disconnected component which is mandatory, but you probably want to have a "normal" notification to use for simple messages.

`Flashy` ships with a base implementation for a notification like that, it supports timed auto-hide with progress bar and showing or not a close button.

To implement it you just need to define how to render its body, similar to how we did with the disconnected component. Here is an example using `PetalComponents` `alert` component:

``` elixir
defmodule MyProjectWeb.Components.Notifications.Normal do
  @moduledoc false

  use MyProjectWeb, :html

  use Flashy.Normal, types: [:info, :success, :warning, :danger]

  import PetalComponents.Alert

  attr :key, :string, required: true
  attr :notification, Flashy.Normal, required: true

  def render(assigns) do
    ~H"""
    <Flashy.Normal.render key={@key} notification={@notification}>
      <.alert
        with_icon
        close_button_properties={close_button_properties(@notification.options, @key)}
        color={color(@notification.type)}
        class="relative overflow-hidden"
      >
        <span><%= Phoenix.HTML.raw(@notification.message) %></span>

        <.progress_bar :if={@notification.options.dismissible?} id={"#{@key}-progress"} />
      </.alert>
    </Flashy.Normal.render>
    """
  end

  attr :id, :string, required: true

  defp progress_bar(assigns) do
    ~H"""
    <div id={@id} class="absolute bottom-0 left-0 h-1 bg-black/10" style="width: 0%" />
    """
  end

  defp color(type), do: to_string(type)

  defp close_button_properties(%{closable?: true}, key),
    do: ["phx-click": JS.exec("data-hide", to: "##{key}")]

  defp close_button_properties(%{closable?: false}, _), do: nil
end
```

Note that you can set any `types` you want to the normal component, you just need to add it to the `types` list when calling `use Flashy.Normal`:

``` elixir
use Flashy.Normal, types: [:info, :fatal, :some_other_type]
```

## Adding a entirely custom notification

You can also create 100% custom notifications for your needs, for example, `Flashy` supports live components when you need to store state or handle events, here I will show a custom notification that will how a form inside with a text input field.

The idea with this notification would be to allow you to create a notification with business logic, for example, if you are creating a chat application, you can have a notification that will allow users to reply to it directly from the notificatio itself.

Here is the implementation:

``` elixir
defmodule MyProjectWeb.Components.Notifications.Custom do
  @moduledoc false

  alias Flashy.{Component, Helpers}

  use MyProjectWeb, :live_component

  use TypedStruct

  import PetalComponents.{Alert, Input, Button}

  typedstruct enforce: true do
    field :question, String.t()

    field :target_module, module
    field :target_id, String.t()

    field :component, Component.t()
  end

  @spec new(String.t(), module, String.t()) :: t
  def new(question, target_module, target_id) do
    struct!(__MODULE__,
      question: question,
      target_module: target_module,
      target_id: target_id,
      component: Component.new(&live_render/1)
    )
  end

  attr :key, :string, required: true
  attr :notification, __MODULE__, required: true

  attr :rest, :global

  def live_render(%{key: key} = assigns) do
    assigns = assign(assigns, id: key)

    ~H"<.live_component module={__MODULE__} {assigns} />"
  end

  def update(assigns, socket) do
    socket = socket |> assign(assigns) |> assign(form: to_form(%{}))

    {:ok, socket}
  end

  def handle_event("send_answer", %{"answer" => answer}, socket) do
    %{id: id, notification: %{target_module: module, target_id: target_id}} = socket.assigns

    send_update(module, id: target_id, answer: answer)

    socket = push_event(socket, "js-exec", %{to: "##{id}", attr: "data-hide"})

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class={Helpers.notification_classes()}
      phx-mounted={Helpers.show_notification(@key)}
      data-hide={Helpers.hide_notification(@key)}
      data-show={Helpers.show_notification(@key)}
      {@rest}
    >
      <.alert with_icon color="info" class="relative overflow-hidden">
        <.form for={@form} phx-submit="send_answer" phx-target={@myself}>
          <div class="flex flex-col gap-2">
            <div><%= Phoenix.HTML.raw(@notification.question) %></div>

            <.input field={@form[:answer]} />

            <.button type="submit" label="Answer" />
          </div>
        </.form>
      </.alert>
    </div>
    """
  end
end

defimpl Flashy.Protocol, for: MyProjectWeb.Components.Notifications.Custom do
  def module(notification), do: notification.component.module

  def function_name(notification), do: notification.component.function_name
end
```

The main takeaway here is that you always need to generate a struct which implements the `Flashy.Protocol`, this is how `Flashy` know which component it needs to call to render.

## Usage

Now that we have `Flashy` installed with some notifications, to use it is pretty simple, here are some examples:

Showing a `info` normal notification:

``` elixir
alias MyProjectWeb.Components.Notifications.Normal

put_notification(socket, Normal.new(:info, "My <i>cool</i> notification"))
```

Flashy supports stacked notifications as-well, so you can do something like this:

``` elixir
alias MyProjectWeb.Components.Notifications.Normal

socket
|> put_notification(Normal.new(:info, "My <i>cool</i> notification"))
|> put_notification(Normal.new(:info, "My another <i>cool</i> notification"))
|> put_notification(Normal.new(:danger, "Fatal error notification"))
```

When using normal notifications, you can also set if they are dimissable and how much time it will be visible:

``` elixir
alias MyProjectWeb.Components.Notifications.Normal

# This option means the notification will never auto-hide, 
# the user will need to close it via the close button 
options_1 = Flashy.Normal.Options.new(dismissible?: false)

# This option means the notification will not show the close button
options_2 = Flashy.Normal.Options.new(closable?: false)

# This option means you can set how much time the notification will show
# before it auto-hides
options_3 = Flashy.Normal.Options.new(dismiss_time: :timer.seconds(2))

socket
|> put_notification(Normal.new(:info, "My <i>cool</i> notification", options_1))
|> put_notification(Normal.new(:info, "My <i>cool</i> notification", options_2))
|> put_notification(Normal.new(:info, "My <i>cool</i> notification", options_3))
```

Finally, we, of course, can also create notifications with our own custom notifications:

``` elixir
alias MyProjectWeb.Components.Notifications.Custom

put_notification(socket, Custom.new("How are you today?", __MODULE__, id))
```

## More examples

You can check how the library works by going to our [examples project](https://github.com/sezaru/flashy_example) to see it working in practice.

## Customizing CSS

By default `Flashy` notifications will show-up on the top right of the screen. But sometimes your requirements can be different, maybe you want the notifications to show-up on the left side, maybe the way `Flashy` default CSS doesn't work well with your project CSS, etc.

`Flashy` uses `PhxComponentHelpers` to customize CSS, you can check the library here: https://hexdocs.pm/phx_component_helpers/PhxComponentHelpers.html

`Flashy` allows to fully customize the CSS, as an example, I will show how to move the notifications to the left.

The first place we can change CSS is to the `Flashy.Container` component, you can update your `lib/<your_app>_web/components/layouts/app.html.heex` file to:

``` elixir
<Flashy.Container.render
  flash={@flash}
  class="!right-0 left-0 !items-end items-start"
/>
```

With this change, we are replacing `right-0` with `left-0` and `items-end` with `items-start`.

Now, we want to customize our components, first, we will want to create a custom transition that will move from the left to right, let's create a module to add that since they are used by all notification components:

``` elixir
defmodule MyProjectWeb.Components.Notifications.Helpers do
  @moduledoc false

  alias Phoenix.LiveView.JS

  def hide_notification(key) do
    JS.hide(
      to: "##{key}",
      transition: {"ease-in duration-300", "translate-x-0", "translate-x-[-100%]"},
      time: 300
    )
    |> JS.push("lv:clear-flash", value: %{key: key})
  end

  def show_notification(key) do
    JS.show(
      to: "##{key}",
      transition: {"ease-in duration-300", "translate-x-[-100%]", "translate-x-0"},
      time: 300
    )
  end
end
```

Now let's start changing our components, let's start with the `Disconnected` one.

First we add the alias to our new helper:

``` elixir
alias MyProjectWeb.Components.Notifications.Helpers
```

Then, inside the `render` function, we change the way we call `Flashy` disconnected render:

``` elixir
<Flashy.Disconnected.render
  key={@key}
  class="!pr-3 pl-3 !translate-x-full translate-x-[-100%]"
  hide_action={Helpers.hide_notification(@key)}
  show_action={Helpers.show_notification(@key)}
>
```

What we are doing here is customize the CSS and the JS actions.

For the CSS, we replaced `!pr-3` with `pl-3` and `translate-x-full` with `translate-x-[-100$]`.

For the JS actions, we are using the ones for our helper instead of `Flashy` built-in ones.

Now, let's do the same for the `Normal` component:

``` elixir
alias FlashyExampleWeb.Components.Notifications.Helpers

...

<Flashy.Normal.render
  key={@key}
  notification={@notification}
  class="!pr-3 pl-3 !translate-x-full translate-x-[-100%]"
  hide_action={Helpers.hide_notification(@key)}
  show_action={Helpers.show_notification(@key)}
>
```

It is exactly the same changes are the `Disconnected` component above.

Finally, we will also update our `Custom` component.

On that one we are importing `Flashy` built-in helpers, se we will replace that with ours:

``` elixir
alias FlashyExampleWeb.Components.Notifications.Helpers

alias Flashy.Component
```

Now we just need to update the component CSS as-well.

In this case we are not using `PhxComponentHelpers`, so we will just implement the full class directly:

``` elixir
<div
  id={@id}
  class={"pointer-events-auto pl-3 select-none drop-shadow flex items-center translate-x-[-100%] hidden"}
  phx-mounted={Helpers.show_notification(@key)}
  data-hide={Helpers.hide_notification(@key)}
  data-show={Helpers.show_notification(@key)}
  {@rest}
>
```

After these changes, your notifications will show up on the left:

[2023-10-23 20-23-15.webm](https://github.com/sezaru/flashy/assets/279828/94e3f31e-a932-42cd-967c-ccedef53dfcf)
