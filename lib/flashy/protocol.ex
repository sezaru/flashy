defprotocol Flashy.Protocol do
  @moduledoc """
  Protocol used to fetch information about the notification component to be rendered.
  """

  @spec module(t) :: module
  def module(notification)

  @spec function_name(t) :: atom
  def function_name(notification)
end
