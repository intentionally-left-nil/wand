defmodule Wand.CLI.Commands.Remove do
  alias Wand.CLI.Display
  alias WandCore.WandFile
  alias Wand.CLI.WandFileWithHelp
  import Wand.CLI.Errors, only: [error: 1]

  @behaviour Wand.CLI.Command
  @moduledoc """
  Remove elixir packages from wand.json

  ## Usage
  **wand** remove [package] [package]
  """
  def help(:missing_package) do
    """
    wand remove must be called with at least one package name.
    For example, wand remove poison.
    See wand help remove --verbose
    """
    |> Display.print()
  end

  def help(:banner), do: Display.print(@moduledoc)
  def help(:verbose), do: help(:banner)

  def validate(args) do
    {_switches, [_ | commands], _errors} = OptionParser.parse(args)

    case commands do
      [] -> {:error, :missing_package}
      names -> {:ok, names}
    end
  end

  def execute(names) do
    with :ok <- Wand.CLI.CoreValidator.require_core(),
      {:ok, file} <- WandFileWithHelp.load(),
         file <- remove_names(file, names),
         :ok <- WandFileWithHelp.save(file),
         :ok <- cleanup() do
      :ok
    else
      {:error, :wand_file_load, reason} ->
        WandFileWithHelp.handle_error(:wand_file_load, reason)

      {:error, :wand_file_save, reason} ->
        WandFileWithHelp.handle_error(:wand_file_save, reason)

      {:error, :require_core, reason} -> Wand.CLI.CoreValidator.handle_error(:require_core, reason)

      {:error, step, reason} ->
        handle_error(step, reason)
    end
  end

  defp remove_names(file, names) do
    Enum.reduce(names, file, &WandFile.remove(&2, &1))
  end

  defp cleanup() do
    case Wand.CLI.Mix.cleanup_deps() do
      :ok -> :ok
      {:error, reason} -> {:error, :cleanup_failed, reason}
    end
  end

  defp handle_error(:cleanup_failed, _reason) do
    """
    # Partial Success
    Unable to run mix deps.unlock --unused

    The wand.json file was successfully updated,
    however, updating the mix.lock file failed
    """
    |> Display.error()

    error(:install_deps_error)
  end
end
