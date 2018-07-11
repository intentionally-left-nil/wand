defmodule Wand.CLI.Commands.Add.Execute do
  @moduledoc false
  alias Wand.CLI.Executor.Result
  alias Wand.CLI.Commands.Add.Package
  alias WandCore.WandFile
  alias WandCore.WandFile.Dependency
  alias Wand.CLI.WandFileWithHelp
  alias Wand.CLI.Display
  alias Wand.CLI.Error

  def execute(packages, %{wand_file: file}) do
    with {:ok, dependencies} <- get_dependencies(packages),
         {:ok, file} <- add_dependencies(file, dependencies) do
      message =
        Enum.map(dependencies, fn %Dependency{name: name, requirement: requirement} ->
          "Succesfully added #{name}: #{requirement}"
        end)
        |> Enum.join("\n")

      {:ok, %Result{wand_file: file, message: message}}
    else
      error -> error
    end
  end

  def after_save(packages) do
    with :ok <- download(packages),
    :ok <- compile(packages) do
      :ok
    else
      error -> error
    end
  end

  defp get_dependencies(packages) do
    dependencies =
      packages
      |> Enum.map(&Task.async(fn -> get_dependency(&1) end))
      |> Enum.map(&Task.await/1)

    case Enum.find(dependencies, &(elem(&1, 0) == :error)) do
      nil -> {:ok, Enum.unzip(dependencies) |> elem(1)}
      {:error, {:not_found, name}} -> {:error, :package_not_found, name}
      {:error, {reason, _name}} -> {:error, :hex_api_error, reason}
    end
  end

  defp get_dependency(%Package{name: name, requirement: {:latest, mode}} = package) do
    case Wand.Hex.releases(name) do
      {:ok, [version | _]} ->
        requirement = Wand.Mode.get_requirement!(mode, version)
        opts = get_opts(package)

        {:ok,
         %Dependency{
           name: name,
           opts: opts,
           requirement: requirement
         }}

      {:error, error} ->
        {:error, {error, name}}
    end
  end

  defp get_dependency(%Package{} = package) do
    {:ok,
     %Dependency{
       name: package.name,
       opts: get_opts(package),
       requirement: package.requirement
     }}
  end

  defp add_dependencies(file, dependencies) do
    Enum.reduce_while(dependencies, {:ok, file}, fn dependency, {:ok, file} ->
      case WandFile.add(file, dependency) do
        {:ok, file} -> {:cont, {:ok, file}}
        {:error, {:already_exists, name}} -> {:halt, {:error, :package_already_exists, name}}
      end
    end)
  end

  defp get_opts(%Package{details: details} = package) do
    get_base_opts(package)
    |> Keyword.merge(get_detail_opts(details))
    |> Enum.into(%{})
  end

  defp get_base_opts(%Package{} = package) do
    [
      :compile_env,
      :only,
      :optional,
      :override,
      :read_app_file,
      :runtime
    ]
    |> get_changed(package, %Package{})
  end

  defp get_detail_opts(details) do
    default =
      Map.fetch!(details, :__struct__)
      |> struct()

    Map.keys(details)
    |> get_changed(details, default)
  end

  defp get_changed(keys, config, default) do
    defaults = Enum.map(keys, &Map.fetch!(config, &1))

    Enum.zip(keys, defaults)
    |> Enum.filter(fn {key, value} ->
      value != Map.fetch!(default, key)
    end)
  end

  defp download([%Package{download: download} | _]) when not download, do: :ok

  defp download(_) do
    case Wand.CLI.Mix.update_deps() do
      :ok -> :ok
      {:error, _reason} -> {:error, :install_deps_error, :download_failed}
    end
  end

  defp compile([%Package{compile: compile} | _]) when not compile, do: :ok

  defp compile(_) do
    case Wand.CLI.Mix.compile() do
      :ok -> :ok
      {:error, _reason} -> {:error, :install_deps_error, :compile_failed}
    end
  end
end
