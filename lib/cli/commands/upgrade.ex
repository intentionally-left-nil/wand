defmodule Wand.CLI.Commands.Upgrade do
  alias Wand.CLI.Display
  @behaviour Wand.CLI.Command

  @moduledoc """
  Upgrade dependencies in your wand.json file

  ## Usage
  wand upgrade
  wand upgrade poison ex_doc --latest

  ## Options
  <pre>
  --compile           Run mix compile after adding (default: **true**)
  --download          Run mix deps.get after adding (default: **true**)
  --latest            Upgrade to the latest version in hex
  --major            Upgrade to the highest version within the current major version
  --minor            Upgrade to the highest version within the current minor version
  </pre>
  """

  defmodule Options do
    defstruct level: :major,
    download: true,
    compile: true
  end

  def help(_type) do
  end

  def validate(args) do
    flags = [
      latest: :boolean,
      major: :boolean,
      minor: :boolean,
      download: :boolean,
      compile: :boolean,
    ]

    {switches, [_ | commands], errors} = OptionParser.parse(args, strict: flags)

    case Wand.CLI.Command.parse_errors(errors) do
      :ok -> {:ok, parse(commands, switches)}
      error -> error
    end
  end

  defp parse(commands, switches) do
    packages = get_packages(commands)
    download = Keyword.get(switches, :download, true)
    compile = download and Keyword.get(switches, :compile, true)
    level = get_level(switches)
    options = %Options{
      download: download,
      compile: compile,
      level: level
    }
    {packages, options}
  end

  defp get_packages([]), do: :all
  defp get_packages(commands), do: commands

  defp get_level(switches) do
    cond do
      Keyword.get(switches, :latest) -> :latest
      Keyword.get(switches, :major) -> :major
      Keyword.get(switches, :minor) -> :minor
      true -> :major
    end
  end
end
