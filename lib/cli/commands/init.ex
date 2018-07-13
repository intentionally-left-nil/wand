defmodule Wand.CLI.Commands.Init do
  use Wand.CLI.Command
  alias Wand.CLI.Display
  alias WandCore.WandFile
  alias WandCore.WandFile.Dependency

  @f WandCore.Interfaces.File.impl()

  @moduledoc """
  # Init
  Convert an elixir project to use wand for dependencies.

  ### Usage
  **wand** init [path] [flags]

  ## Examples
  ```
  wand init
  wand init /path/to/project
  wand init --overwrite
  ```

  ## Options
  By default, wand init will refuse to overwrite an existing wand.json file. It will also refuse to install the wand.core task without confirmation. This is controllable via flags.


  ```
  --overwrite           Ignore the presence of an existing wand.json file, and create a new one
  ```
  """

  @doc false
  def help(:banner), do: Display.print(@moduledoc)

  @doc false
  def help(:verbose) do
    """
    wand init walks through the current list of dependencies for a project, and transfers it to wand.json.

    Additionally, it will attempt to modify the mix.exs file to use the wand.core task to load the modules. If that fails, you need to manually edit your mix.exs file.

    The task attempts to be non-destructive. It will not create a new wand.json file if one exists, unless the overwrite flag is present.

    ## Options
    By default, wand init will refuse to overwrite an existing wand.json file. This is controllable via flags.


    ```
    --overwrite           Ignore the presence of an existing wand.json file, and create a new one
    ```
    """
    |> Display.print()
  end

  @doc false
  def help({:invalid_flag, flag}) do
    """
    #{flag} is invalid.
    Valid flags are --overwrite and --force
    See wand help init --verbose for more information
    """
    |> Display.print()
  end

  def options() do
    [require_core: true]
  end

  @doc false
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

  @doc false
  def execute({path, switches}, %{}) do
    file = %WandFile{}

    with :ok <- can_write?(path, switches),
         {:ok, deps} <- get_dependencies(path),
         {:ok, file} <- add_dependencies(file, deps) do
      message = """
      Successfully initialized wand.json and copied your dependencies to it.
      Type wand add [package] to add new packages, or wand upgrade to upgrade them
      """

      {:ok, %Result{wand_file: file, wand_path: path, message: message}}
    else
      error -> error
    end
  end

  def after_save({path, _switches}) do
    update_mix_file(path)
  end

  @doc false
  def handle_error(:file_already_exists, path) do
    """
    # Error
    File already exists

    The file #{path} already exists.

    If you want to override it, use the --overwrite flag
    """
  end

  @doc false
  def handle_error(:wand_core_api_error, _reason) do
    """
    # Error
    Unable to read existing deps

    mix wand.init did not return successfully.
    Usually that means your mix.exs file is invalid. Please make sure your existing deps are correct, and then try again.
    """
  end

  @doc false
  def handle_error(:mix_file_not_updated, nil) do
    """
    # Partial Success
    wand.json was successfully created with your dependencies, however your mix.exs file could not be updated to use it. To complete the process, you need to change your deps() in mix.exs to the following:

    deps: Mix.Tasks.WandCore.Deps.run([])
    """
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
      @f.exists?(path) -> {:error, :file_already_exists, path}
      true -> :ok
    end
  end

  defp get_dependencies(path) do
    deps =
      Path.dirname(path)
      |> Wand.CLI.Mix.get_deps()

    case deps do
      {:ok, deps} ->
        Enum.map(deps, &convert_dependency/1)
        |> validate_dependencies()

      {:error, reason} ->
        {:error, :wand_core_api_error, reason}
    end
  end

  defp validate_dependencies(dependencies) do
    case Enum.find(dependencies, &(elem(&1, 0) == :error)) do
      nil ->
        dependencies = Enum.unzip(dependencies) |> elem(1)
        {:ok, dependencies}

      {:error, error} ->
        {:error, :wand_core_api_error, error}
    end
  end

  defp add_dependencies(file, dependencies) do
    Enum.reduce(dependencies, {:ok, file}, fn dependency, {:ok, file} ->
      WandFile.add(file, dependency)
    end)
  end

  defp convert_dependency([name, opts]) when is_list(opts) do
    opts = WandCore.Opts.decode(opts)
    convert_dependency([name, nil, opts])
  end

  defp convert_dependency([name, requirement]), do: convert_dependency([name, requirement, []])

  defp convert_dependency([name, requirement, opts]) do
    opts =
      WandCore.Opts.decode(opts)
      |> Enum.into(%{}, fn [key, val] -> {String.to_atom(key), val} end)

    {:ok, %Dependency{name: name, requirement: requirement, opts: opts}}
  end

  defp convert_dependency(_), do: {:error, :invalid_dependency}

  defp update_mix_file(path) do
    mix_file =
      Path.dirname(path)
      |> Path.join("mix.exs")

    with true <- @f.exists?(mix_file),
         {:ok, contents} <- @f.read(mix_file),
         true <- String.contains?(contents, "deps: deps()"),
         new_contents <-
           String.replace(contents, "deps: deps()", "deps: Mix.Tasks.WandCore.Deps.run([])"),
         :ok <- @f.write(mix_file, new_contents) do
      :ok
    else
      _ -> {:error, :mix_file_not_updated, nil}
    end
  end
end
