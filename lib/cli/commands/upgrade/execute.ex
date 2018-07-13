defmodule Wand.CLI.Commands.Upgrade.Execute do
  @moduledoc false
  alias Wand.Mode
  alias WandCore.WandFile
  alias WandCore.WandFile.Dependency
  alias Wand.CLI.Commands.Upgrade.Options
  alias Wand.CLI.Executor.Result

  def execute({names, %Options{} = options}, %{wand_file: file}) do
    with {:ok, dependencies} <- get_dependencies(file, names),
         {:ok, file} <- update_dependencies(file, dependencies, options) do
      {:ok, %Result{wand_file: file}}
    else
      error -> error
    end
  end

  def handle_error(:package_not_found, name) do
    """
    # Error
    Could not find #{name} in wand.json
    Did you mean to type wand add #{name} instead?
    """
  end

  def handle_error(:hex_api_error, {reason, name}) do
    """
    # Error
    There was a problem finding the latest version for #{name}.
    The exact reason was #{reason}
    """
  end

  defp get_dependencies(%WandFile{dependencies: dependencies}, :all), do: {:ok, dependencies}

  defp get_dependencies(%WandFile{dependencies: dependencies}, names) do
    Enum.reduce_while(names, {:ok, []}, fn name, {:ok, filtered} ->
      case Enum.find(dependencies, &(&1.name == name)) do
        nil -> {:halt, {:error, :package_not_found, name}}
        item -> {:cont, {:ok, [item | filtered]}}
      end
    end)
  end

  defp update_dependencies(file, dependencies, options) do
    Enum.reduce_while(dependencies, {:ok, []}, fn dependency, {:ok, filtered} ->
      case update_dependency(dependency, options) do
        {:ok, dependency} -> {:cont, {:ok, [dependency | filtered]}}
        {:error, reason} -> {:halt, {:error, :hex_api_error, reason}}
      end
    end)
    |> case do
      {:ok, dependencies} ->
        file = %WandFile{file | dependencies: dependencies}
        {:ok, file}

      error ->
        error
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

  defp update_hex_requirement(requirement, releases, %Options{latest: false}, mode) do
    Enum.find(releases, &Version.match?(&1, requirement))
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
end
