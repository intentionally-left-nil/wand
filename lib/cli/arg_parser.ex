defmodule Wand.CLI.ArgParser do
  def parse(args) do
    {_, main_commands, _} = OptionParser.parse(args)

    case main_commands do
      [] -> {:help, nil, nil}
      ["help"] -> {:help, nil, nil}
      ["add" | _rest] -> validate("add", args)
      ["a" | _rest] -> validate("add", args)
      ["remove" | _rest] -> validate("remove", args)
      ["r" | _rest] -> validate("remove", args)
      [command | _rest] -> {:help, {:unrecognized, command}}
    end
  end

  defp validate(name, args) do
    module = Module.concat(Wand.CLI.Commands, String.capitalize(name))
    a_name = String.to_atom(name)

    case Kernel.apply(module, :validate, [args]) do
      {:ok, response} -> {a_name, response}
      {:error, reason} -> {:help, a_name, reason}
    end
  end
end
