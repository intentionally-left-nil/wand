defmodule Wand.CLI.Commands.Init do
  @behaviour Wand.CLI.Command
  alias Wand.CLI.Display

  @moduledoc """
  Convert an elixir project to use wand for dependencies. This command also installs the wand.core tasks if not installed.

  ## Usage
  **wand** init [path] [flags]

  ## Examples
  <pre>
  **wand** init
  **wand** init /path/to/project
  **wand** init --overwrite
  </pre>

  ## Options
  By default, wand init will refuse to overwrite an existing wand.json file. It will also refuse to install the wand.core task without confirmation. This is controllable via flags.
  <pre>
  --overwrite           Ignore the presence of an existing wand.json file, and create a new one
  --force               Always replace the existing wand.json file, and always install the core task, if needed.
  </pre>
  """

  def help(:banner), do: Display.print(@moduledoc)

  def help(:verbose) do
    """
    wand init walks through the current list of dependencies for a project, and transfers it to wand.json.

    Additionally, it will attempt to modify the mix.exs file to use the wand.core task to load the modules. If that fails, you need to manually edit your mix.exs file.

    The task attempts to be non-destructive. It will not create a new wand.json file if one exists, unless the overwrite flag is present. It will not download the wand.core archive without prompting.

    ## Options
    By default, wand init will refuse to overwrite an existing wand.json file. It will also refuse to install the wand.core task without confirmation. This is controllable via flags.
    <pre>
    --overwrite           Ignore the presence of an existing wand.json file, and create a new one
    --force               Always replace the existing wand.json file, and always install the core task, if needed.
    </pre>
    """
    |> Display.print()
  end

  def help({:invalid_flag, flag}) do
    """
    #{flag} is invalid.
    Valid flags are --overwrite and --force
    See wand help init --verbose for more information
    """
    |> Display.print()
  end

  def validate(args) do
    flags = [
      overwrite: :boolean,
      force: :boolean
    ]

    {switches, [_ | commands], errors} = OptionParser.parse(args, strict: flags)

    case Wand.CLI.Command.parse_errors(errors) do
      :ok -> get_path(commands, switches)
      error -> error
    end
  end

  defp get_path([], switches), do: {:ok, {"./", switches}}
  defp get_path([path], switches), do: {:ok, {path, switches}}
  defp get_path(_, _), do: {:error, :wrong_command}
end
