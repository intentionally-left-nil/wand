defmodule Wand.CLI.Commands.Remove do
  use Wand.CLI.Command
  alias Wand.CLI.Display
  alias WandCore.WandFile

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
  @impl true
  def help(:missing_package) do
    """
    wand remove must be called with at least one package name.
    For example, wand remove poison.
    See wand help remove --verbose
    """
    |> Display.print()
  end

  @doc false
  @impl true
  def help(:banner), do: Display.print(@moduledoc)
  @doc false
  @impl true
  def help(:verbose), do: help(:banner)

  @impl true
  def options() do
    [
      require_core: true,
      load_wand_file: true,
    ]
  end

  @doc false
  @impl true
  def validate(args) do
    {_switches, [_ | commands], _errors} = OptionParser.parse(args)

    case commands do
      [] -> {:error, :missing_package}
      names -> {:ok, names}
    end
  end

  @doc false
  @impl true
  def execute(names, %{wand_file: file}) do
    file = remove_names(file, names)
    {:ok, %Result{wand_file: file}}
  end

  @doc false
  @impl true
  def after_save(_data) do
    case Wand.CLI.Mix.cleanup_deps() do
      :ok -> :ok
      {:error, _} -> {:error, :install_deps_error, nil}
    end
  end

  @doc false
  @impl true
  def handle_error(:install_deps_error, nil) do
    """
    # Partial Success
    Unable to run mix deps.unlock --unused

    The wand.json file was successfully updated,
    however, updating the mix.lock file failed
    """
  end

  defp remove_names(file, names) do
    Enum.reduce(names, file, &WandFile.remove(&2, &1))
  end
end
