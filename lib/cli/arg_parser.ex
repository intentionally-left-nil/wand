defmodule Wand.CLI.ArgParser do
  @moduledoc false

  def parse(args) do
    global_flags = [
      version: :boolean
    ]

    {flags, commands, _} = OptionParser.parse(args, strict: global_flags)

    cond do
      Keyword.has_key?(flags, :version) -> validate(:version, args)
      true -> parse_main(args, commands)
    end
  end

  defp parse_main(args, []), do: validate(:help, ["help"] ++ args)

  @commands Wand.CLI.Command.routes() ++ ["a", "r", "u"]
  defp parse_main(args, [command | _rest]) when command in @commands do
    %{
      "a" => "add",
      "r" => "remove",
      "u" => "upgrade"
    }
    |> Map.get(command, command)
    |> String.to_atom()
    |> validate(args)
  end

  defp parse_main(_args, [command | _rest]), do: {:help, :help, {:unrecognized, command}}

  defp validate(key, args) do
    module = Wand.CLI.Command.get_module(key)
    case module.validate(args) do
      {:ok, response} -> {key, response}
      {:error, reason} -> {:help, key, reason}
      {:help, module, reason} -> {:help, module, reason}
    end
  end
end
