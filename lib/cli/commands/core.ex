defmodule Wand.CLI.Commands.Core do
  alias Wand.CLI.Display
  @behaviour Wand.CLI.Command
  @moduledoc """
  Manage the related wand-core tasks
  ## Usage
  <pre>
  **wand** core install [--force]
  **wand** core uninstall
  </pre>
  """

  def help(:banner), do: Display.print(@moduledoc)

  def help(:verbose) do
    """
    Wand comes in two parts, the CLI and the wand.core tasks.
    In order to run mix deps.get, only the wand.core tasks are needed. For everything else, the CLI is needed.

    Wand validates to make sure the CLI is using a compatible version of WandCore. If they get out of sync, you can type wand core upgrade to fix the issue.

    ## Options
    wand core install will install the archive globally. By default, it will _not_ overwrite an older version of WandCore. You can pass in the --latest flag to do so.

    wand core uninstall will remove the core task globally.
    """
    |> Display.print()
  end

  def help(:wrong_command) do
    """
    The command is invalid.
    The correct commands are:
    <pre>
    wand core install [--force]
    wand core uninstall
    wand core --version
    </pre>
    See wand help core --verbose for more information
    """
    |> Display.print()
  end

  def validate(args) do
    {switches, [_ | commands], errors} = OptionParser.parse(args, get_flags(args))
    case Wand.CLI.Command.parse_errors(errors) do
      :ok -> parse(commands, switches)
      error -> error
    end
  end

  defp parse([], switches) do
    case Keyword.get(switches, :version) do
      true -> {:ok, :version}
      _ -> {:error, :wrong_command}
    end
  end

  defp parse(commands, switches) do
    case commands do
      ["install"] -> {:ok, {:install, switches}}
      ["uninstall"] -> {:ok, :uninstall}
      ["version"] -> {:ok, :version}
      _ -> {:error, :wrong_command}
    end
  end

  defp get_flags(args) do
    {_switches, [_ | commands], _errors} = OptionParser.parse(args)
    case commands do
      ["install"] -> [force: :boolean]
      ["version"] -> [version: :boolean]
      [] -> [version: :boolean]
      _ -> []
    end
  end
end
