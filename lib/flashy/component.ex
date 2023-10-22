defmodule Flashy.Component do
  @moduledoc """
  Struct containing a notification module and function for being used later with `apply/3` function.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :module, module
    field :function_name, atom
  end

  @spec new(function) :: t
  def new(function) do
    {:name, name} = Function.info(function, :name)
    {:module, module} = Function.info(function, :module)

    new(module, name)
  end

  @spec new(module, atom) :: t
  def new(module, function_name),
    do: struct!(__MODULE__, module: module, function_name: function_name)
end
