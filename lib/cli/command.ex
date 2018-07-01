defmodule Wand.CLI.Command do
  @moduledoc """
  The interface for each type of command that wand supports.
  To add a new command, the following things must take place:

  1. Add the name of the module to routes below
  2. Create a module inside the lib/cli/commands folder that implements `Wand.CLI.Command`
  3. Update `Wand.CLI.ArgParser` if you need to add a shorthand version
  4. Update the help file in `Wand` with the appropriate text
  """

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
