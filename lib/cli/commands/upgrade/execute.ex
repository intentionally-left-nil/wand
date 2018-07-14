defmodule Wand.CLI.Commands.Upgrade.Execute do
  @moduledoc false
  alias Wand.Mode
  alias WandCore.WandFile
  alias WandCore.WandFile.Dependency
  alias Wand.CLI.Commands.Upgrade.Options
  alias Wand.CLI.Executor.Result
  alias Wand.CLI.DependencyDownloader

  def execute({names, %Options{} = options}, %{wand_file: file}) do
    with names <- parse_names(names, file, options),
         {:ok, file} <- update_dependencies(file, names, options) do
      {:ok, %Result{wand_file: file}}
    else
      error -> error
    end
  end

  def after_save({_names, %Options{} = options}), do: download(options)

  def handle_error(:hex_api_error, {reason, name}) do
    """
    # Error
    There was a problem finding the latest version for #{name}.
    The exact reason was #{reason}
    """
  end

  defp parse_names(:all, %WandFile{dependencies: dependencies}, options) do
    Enum.map(dependencies, & &1.name)
    |> remove_skips(options)
  end

  defp parse_names(names, _dependencies, options), do: remove_skips(names, options)

  defp remove_skips(dependencies, %Options{skip: skip}) do
    Enum.reject(dependencies, &Enum.member?(skip, &1))
  end

  defp update_dependencies(%WandFile{dependencies: dependencies} = file, names, options) do
    Enum.map_reduce(dependencies, :ok, fn
      dependency, :ok ->
        case Enum.member?(names, dependency.name) do
          true -> update_dependency(dependency, options)
          false -> {:ok, dependency}
        end
        |> case do
          {:ok, dependency} -> {dependency, :ok}
          {:error, error} -> {:error, {:error, error}}
        end

      _dependency, error ->
        {:error, error}
    end)
    |> case do
      {dependencies, :ok} -> {:ok, %WandFile{file | dependencies: dependencies}}
      {_dependencies, {:error, reason}} -> {:error, :hex_api_error, reason}
    end
  end

  defp update_dependency(%Dependency{name: name, requirement: requirement} = dependency, options) do
    with {:source, :hex} <- {:source, Dependency.source(dependency)},
         mode <- Mode.from_requirement(requirement),
         {:ok, requirement} <- update_requirement(dependency, options, mode) do
      {:ok, %Dependency{dependency | requirement: requirement}}
    else
      # Non-hex dependencies are currently not touched by wand
      {:source, _source} ->
        {:ok, dependency}

      {:error, error} ->
        {:error, {error, name}}
    end
  end

  defp update_requirement(
         %Dependency{requirement: requirement},
         %Options{latest: false},
         :custom
       ),
       do: {:ok, requirement}

  defp update_requirement(%Dependency{requirement: requirement}, %Options{latest: false}, :exact),
    do: {:ok, requirement}

  defp update_requirement(%Dependency{name: name, requirement: requirement}, options, mode) do
    case Wand.Hex.releases(name) do
      {:ok, releases} ->
        releases = sort_releases(releases)
        requirement = update_hex_requirement(requirement, releases, options, mode)
        {:ok, requirement}

      error ->
        error
    end
  end

  defp update_hex_requirement(requirement, releases, %Options{latest: false, pre: pre}, mode) do
    Enum.find(releases, &Version.match?(&1, requirement, allow_pre: pre))
    |> case do
      nil -> requirement
      version -> Mode.get_requirement!(mode, version)
    end
  end

  defp update_hex_requirement(_requirement, [version | _], %Options{mode: mode}, _mode) do
    Mode.get_requirement!(mode, version)
  end

  defp sort_releases(releases) do
    Enum.sort(releases, fn a, b ->
      case Version.compare(a, b) do
        :lt -> false
        _ -> true
      end
    end)
  end

  defp download(%Options{download: false}), do: :ok
  defp download(_), do: DependencyDownloader.download()
end
