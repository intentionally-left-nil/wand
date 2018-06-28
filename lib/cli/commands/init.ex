defmodule Wand.CLI.Commands.Init do
  @behaviour Wand.CLI.Command
  alias Wand.CLI.Display
  alias Wand.WandFile
  alias Wand.CLI.WandFileWithHelp
  import Wand.CLI.Errors, only: [error: 1]

  @f Wand.Interfaces.File.impl()

  @moduledoc """
  Convert an elixir project to use wand for dependencies.

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
  </pre>
  """

  def help(:banner), do: Display.print(@moduledoc)

  def help(:verbose) do
    """
    wand init walks through the current list of dependencies for a project, and transfers it to wand.json.

    Additionally, it will attempt to modify the mix.exs file to use the wand.core task to load the modules. If that fails, you need to manually edit your mix.exs file.

    The task attempts to be non-destructive. It will not create a new wand.json file if one exists, unless the overwrite flag is present.

    ## Options
    By default, wand init will refuse to overwrite an existing wand.json file. This is controllable via flags.
    <pre>
    --overwrite           Ignore the presence of an existing wand.json file, and create a new one
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
      overwrite: :boolean
    ]

    {switches, [_ | commands], errors} = OptionParser.parse(args, strict: flags)

    case Wand.CLI.Command.parse_errors(errors) do
      :ok -> get_path(commands, switches)
      error -> error
    end
  end

  def execute({path, switches}) do
    with :ok <- can_write?(path, switches),
         :ok <- WandFileWithHelp.save(%WandFile{}, path) do
      :ok
    else
      {:error, :wand_file_save, reason} ->
        WandFileWithHelp.handle_error(:wand_file_save, reason)

      {:error, step, reason} ->
        handle_error(step, reason)
    end
  end

  defp get_path([], switches), do: {:ok, {"wand.json", switches}}

  defp get_path([path], switches) do
    path =
      case Path.basename(path) do
        "wand.json" -> path
        _ -> Path.join(path, "wand.json")
      end

    {:ok, {path, switches}}
  end

  defp get_path(_, _), do: {:error, :wrong_command}

  defp can_write?(path, switches) do
    cond do
      Keyword.get(switches, :overwrite) -> :ok
      @f.exists?(path) -> {:error, :file_exists, path}
      true -> :ok
    end
  end

  defp handle_error(:file_exists, path) do
    """
    # Error
    File already exists

    The file #{path} already exists.

    If you want to override it, use the --overwrite flag
    """
    |> Display.error()

    error(:file_already_exists)
  end
end
