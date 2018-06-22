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

  defp parse_main(args, []), do: validate("help", args)
  @commands ["add", "a", "help", "init", "outdated", "remove", "r", "upgrade", "u", "version"]
  defp parse_main(args, [command | _rest]) when command in @commands do
    %{
      "a" => "add",
      "r" => "remove",
      "u" => "upgrade"
    }
    |> Map.get(command, command)
    |> validate(args)
  end

  defp parse_main(_args, [command | _rest]), do: {:help, {:unrecognized, command}}

  defp validate(name, args) do
    module = Module.concat(Wand.CLI.Commands, String.capitalize(name))
    a_name = String.to_atom(name)

    case Kernel.apply(module, :validate, [args]) do
      {:ok, response} -> {a_name, response}
      {:error, reason} -> {:help, a_name, reason}
      {:help, module, reason} -> {:help, module, reason}
    end
  end
end
