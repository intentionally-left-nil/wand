defmodule Wand.CLI.Commands.Remove do
  alias Wand.CLI.Display
  alias WandCore.WandFile
  alias Wand.CLI.Error

  @behaviour Wand.CLI.Command
  @moduledoc """
  # Remove
  Remove elixir packages from wand.json

  ### Usage
  **wand** remove [package] [package]

  ## Examples
  ```
  wand remove poison
  wand remove poison ex_doc mox my_git_package
  ```
  """
  @doc false
  def help(:missing_package) do
    """
    wand remove must be called with at least one package name.
    For example, wand remove poison.
    See wand help remove --verbose
    """
    |> Display.print()
  end

  @doc false
  def help(:banner), do: Display.print(@moduledoc)
  @doc false
  def help(:verbose), do: help(:banner)

  def options() do
    [
      require_core: true,
      load_wand_file: true,
    ]
  end

  @doc false
  def validate(args) do
    {_switches, [_ | commands], _errors} = OptionParser.parse(args)

    case commands do
      [] -> {:error, :missing_package}
      names -> {:ok, names}
    end
  end

  @doc false
  def execute(names, %{wand_file: file}) do
    file = remove_names(file, names)
    {:ok, file}
  end

  @doc false
  def after_save() do
    case Wand.CLI.Mix.cleanup_deps() do
      :ok -> :ok
      {:error, _} -> cleanup_failed()
    end
  end

  defp remove_names(file, names) do
    Enum.reduce(names, file, &WandFile.remove(&2, &1))
  end

  defp cleanup_failed() do
    """
    # Partial Success
    Unable to run mix deps.unlock --unused

    The wand.json file was successfully updated,
    however, updating the mix.lock file failed
    """
    |> Display.error()

    Error.get(:install_deps_error)
  end
end
