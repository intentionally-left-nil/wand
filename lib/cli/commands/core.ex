defmodule Wand.CLI.Commands.Core do
  alias Wand.CLI.Display
  @behaviour Wand.CLI.Command
  @moduledoc """
  Manage the related wand-core tasks
  ## Usage
  **wand** core install
  **wand** core uninstall
  """

  def help(:banner), do: Display.print(@moduledoc)

  def help(:verbose) do
    """
    Wand comes in two parts, the CLI and the wand.core tasks.
    In order to run mix deps.get, only the wand.core tasks are needed. For everything else, the CLI is needed.

    This command lets you control wand.core and install it if missing.
    """
    |> Display.print()
  end

  def help(:wrong_command) do
    """
    The command is invalid.
    The correct commands are:
    <pre>
    wand core install
    wand core uninstall
    </pre>
    See wand help core --verbose for more information
    """
    |> Display.print()
  end

  def validate(args) do
    {_switches, [_ | commands], _errors} = OptionParser.parse(args)
    parse(commands)
  end

  defp parse(["install"]), do: {:ok, :install}
  defp parse(["uninstall"]), do: {:ok, :uninstall}
  defp parse(_commands), do: {:error, :wrong_command}
end
