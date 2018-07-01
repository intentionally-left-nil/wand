defmodule Wand.CLI.ArgParser do
  @moduledoc false
  alias Wand.CLI.Command

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

  @commands [
    "add",
    "a",
    "core",
    "help",
    "init",
    "outdated",
    "remove",
    "r",
    "upgrade",
    "u",
    "version"
  ]
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
    case Command.route(key, :validate, [args]) do
      {:ok, response} -> {key, response}
      {:error, reason} -> {:help, key, reason}
      {:help, module, reason} -> {:help, module, reason}
    end
  end
end
