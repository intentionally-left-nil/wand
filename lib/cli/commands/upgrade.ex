defmodule Wand.CLI.Commands.Upgrade do
  @behaviour Wand.CLI.Command

  def validate(args) do
    flags = [
      latest: :boolean,
      major: :boolean,
      minor: :boolean,
      patch: :boolean
    ]

    {switches, [_ | commands], errors} = OptionParser.parse(args, strict: flags)

    case parse_errors(errors) do
      :ok -> {:ok, {get_packages(commands), get_level(switches)}}
      error -> error
    end
  end

  defp get_packages([]), do: :all
  defp get_packages(commands), do: commands

  defp parse_errors([]), do: :ok

  defp parse_errors([{flag, _} | _rest]) do
    {:error, {:invalid_flag, flag}}
  end

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
