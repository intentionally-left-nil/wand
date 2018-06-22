defmodule Wand.CLI.ArgParser do
  def parse(args) do
    global_flags = [
      version: :boolean
    ]
    {flags, commands, _} = OptionParser.parse(args, strict: global_flags)

    cond do
      Keyword.has_key?(flags, :version) -> validate("version", args)
      true -> parse_main(args, commands)
    end
  end

  defp parse_main(args, commands) do
    case commands do
      [] -> {:help, nil, nil}
      ["help"] -> {:help, nil, nil}
      ["add" | _rest] -> validate("add", args)
      ["a" | _rest] -> validate("add", args)
      ["init" | _rest] -> validate("init", args)
      ["outdated" | _rest] -> validate("outdated", args)
      ["remove" | _rest] -> validate("remove", args)
      ["r" | _rest] -> validate("remove", args)
      ["upgrade" | _rest] -> validate("upgrade", args)
      ["u" | _rest] -> validate("upgrade", args)
      ["version" | _rest] -> validate("version", args)
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
