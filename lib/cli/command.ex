defmodule Wand.CLI.Command do
  @callback validate(args :: list) :: {:ok, any()} | {:error, any()}

  def route(key, name, args) do
    get_module(key)
    |> Kernel.apply(name, args)
  end

  defp get_module(name) when is_atom(name), do: get_module(to_string(name))
  defp get_module(name) do
    Module.concat(Wand.CLI.Commands, String.capitalize(name))
  end
end
