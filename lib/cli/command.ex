defmodule Wand.CLI.Command do
  @callback execute(data :: any()) :: :ok | {:error, integer()}
  @callback help(type :: any()) :: any()
  @callback validate(args :: list) :: {:ok, any()} | {:error, any()}

  def routes() do
    [
      "add",
      "core",
      "help",
      "init",
      "outdated",
      "remove",
      "upgrade",
      "version"
    ]
  end

  def route(key, name, args) do
    get_module(key)
    |> Kernel.apply(name, args)
  end

  def parse_errors([]), do: :ok

  def parse_errors([{flag, _} | _rest]) do
    {:error, {:invalid_flag, flag}}
  end

  defp get_module(name) when is_atom(name), do: get_module(to_string(name))

  defp get_module(name) do
    Module.concat(Wand.CLI.Commands, String.capitalize(name))
  end
end
