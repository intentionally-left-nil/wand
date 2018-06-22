defmodule Wand.CLI.Commands.Upgrade do
  @behaviour Wand.CLI.Command

  def help(_type) do
  end

  def validate(args) do
    flags = [
      latest: :boolean,
      major: :boolean,
      minor: :boolean,
      patch: :boolean
    ]

    {switches, [_ | commands], errors} = OptionParser.parse(args, strict: flags)

    case Wand.CLI.Command.parse_errors(errors) do
      :ok -> {:ok, {get_packages(commands), get_level(switches)}}
      error -> error
    end
  end

  defp get_packages([]), do: :all
  defp get_packages(commands), do: commands

  defp get_level(switches) do
    cond do
      Keyword.get(switches, :latest) -> :major
      Keyword.get(switches, :major) -> :major
      Keyword.get(switches, :minor) -> :minor
      Keyword.get(switches, :patch) -> :patch
      true -> :major
    end
  end
end
