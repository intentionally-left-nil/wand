defmodule Wand.CLI.Commands.Upgrade do
  import Wand.CLI.Errors, only: [error: 1]
  alias Wand.CLI.Display
  alias WandCore.WandFile
  alias Wand.CLI.WandFileWithHelp
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
  --latest            Upgrade to the latest version, ignoring wand.json restrictions
  </pre>

  The following flags are additionally allowed if --latest is passed in:
  <pre>
  --caret             After updating, set the version in wand.json with ^ semantics
  --exact             After updating, set the version in wand.json with ^ semantics
  --tilde             After updating, set the version in wand.json with ~> semantics
  </pr>
  """

  defmodule Options do
    defstruct mode: nil,
              download: true,
              compile: true,
              latest: false
  end

  def help(:banner), do: Display.print(@moduledoc)
  def help(:verbose), do: help(:banner)

  def help({:invalid_flag, flag}) do
    """
    #{flag} is invalid.
    Allowed flags are --caret, --compile, --download, --exact, --latest, and --tilde.
    See wand help upgrade --verbose for more information
    """
    |> Display.print()
  end

  def validate(args) do
    {switches, [_ | commands], errors} = OptionParser.parse(args, strict: get_flags(args))

    case Wand.CLI.Command.parse_errors(errors) do
      :ok -> {:ok, parse(commands, switches)}
      error -> error
    end
  end

  def execute({names, %Options{}=options}) do
    with {:ok, file} <- WandFileWithHelp.load(),
    {:ok, dependencies} <- get_dependencies(file, names)
    do
      :ok
    else
      {:error, :wand_file_load, reason} ->
        WandFileWithHelp.handle_error(:wand_file_load, reason)

      {:error, :wand_file_save, reason} ->
        WandFileWithHelp.handle_error(:wand_file_save, reason)

      {:error, step, reason} ->
        handle_error(step, reason)
    end
  end

  defp get_dependencies(%WandFile{dependencies: dependencies}, :all), do: {:ok, dependencies}

  defp get_dependencies(%WandFile{dependencies: dependencies}, names) do
    dependencies = Enum.map(names, fn name -> Enum.find(dependencies, {:error, name}, &(&1.name == name)) end)

    case Enum.find(dependencies, &(elem(&1, 0) == :error)) do
      nil -> {:ok, dependencies}
      {:error, error} -> {:error, :get_dependencies, error}
    end
  end

  defp parse(commands, switches) do
    download = Keyword.get(switches, :download, true)
    compile = download and Keyword.get(switches, :compile, true)
    options = %Options{
      download: download,
      compile: compile,
      latest: Keyword.get(switches, :latest, false),
      mode: get_mode(switches)
    }

    {get_packages(commands), options}
  end

  defp get_packages([]), do: :all
  defp get_packages(commands), do: commands

  defp get_mode(switches) do
    cond do
      Keyword.get(switches, :exact) -> :exact
      Keyword.get(switches, :tilde) -> :tilde
      Keyword.get(switches, :caret) -> :caret
      true -> nil
    end
  end

  defp get_flags(args) do
    base_flags = [
      compile: :boolean,
      download: :boolean,
      latest: :boolean,
    ]
    latest_flags = [
      caret: :boolean,
      exact: :boolean,
      tilde: :boolean,
    ]

    {switches, _commands, _errors} = OptionParser.parse(args)
    case Keyword.get(switches, :latest) do
      true -> latest_flags ++ base_flags
      _ -> base_flags
    end
  end

  defp handle_error(:get_dependencies, name) do
    """
    # Error
    Could not find #{name} in wand.json
    Did you mean to type wand add #{name} instead?
    """
    |> Display.error()
    error(:package_not_found)
  end
end
