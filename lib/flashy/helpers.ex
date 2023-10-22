defmodule Flashy.Helpers do
  @moduledoc false

  alias Phoenix.LiveView.JS

  def notification_classes do
    "pointer-events-auto pr-3 select-none drop-shadow flex items-center translate-x-full hidden"
  end

  def hide_notification(key) do
    JS.hide(
      to: "##{key}",
      transition: {"ease-in duration-300", "translate-x-0", "translate-x-full"},
      time: 300
    )
    |> JS.push("lv:clear-flash", value: %{key: key})
  end

  def show_notification(key) do
    JS.show(
      to: "##{key}",
      transition: {"ease-in duration-300", "translate-x-full", "translate-x-0"},
      time: 300
    )
  end
end
