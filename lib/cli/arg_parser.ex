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

  defp parse_main(_args, []), do: {:help, nil, nil}
  @commands ["add", "init", "outdated", "remove", "upgrade", "version"]
  defp parse_main(args, [command | _rest]) when command in @commands do
    validate(command, args)
  end
  defp parse_main(args, [command | _rest]) do
    case command do
      "help" -> {:help, nil, nil}
      "a" -> validate("add", args)
      "r" -> validate("remove", args)
      "u" -> validate("upgrade", args)
      command -> {:help, {:unrecognized, command}}
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
