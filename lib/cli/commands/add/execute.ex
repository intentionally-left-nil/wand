defmodule Wand.CLI.Commands.Add.Execute do
  alias Wand.CLI.Commands.Add.Package
  alias Wand.WandFile
  alias Wand.WandFile.Dependency
  alias Wand.CLI.WandFileWithHelp
  alias Wand.CLI.Display
  import Wand.CLI.Errors, only: [error: 1]

  def execute(packages) do
    with {:ok, file} <- WandFileWithHelp.load(),
         {:ok, dependencies} <- get_dependencies(packages),
         {:ok, file} <- add_dependencies(file, dependencies),
         :ok <- WandFileWithHelp.save(file),
         :ok <- download(packages),
         :ok <- compile(packages) do
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

  defp get_dependencies(packages) do
    dependencies =
      packages
      |> Enum.map(&Task.async(fn -> get_dependency(&1) end))
      |> Enum.map(&Task.await/1)

    case Enum.find(dependencies, &(elem(&1, 0) == :error)) do
      nil -> {:ok, Enum.unzip(dependencies) |> elem(1)}
      {:error, error} -> {:error, :dependency, error}
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
        {:error, reason} -> {:halt, {:error, :add_dependency, reason}}
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

  def get_detail_opts(details) do
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
      {:error, reason} -> {:error, :download_failed, reason}
    end
  end

  defp compile([%Package{compile: compile} | _]) when not compile, do: :ok

  defp compile(_) do
    case Wand.CLI.Mix.compile() do
      :ok -> :ok
      {:error, reason} -> {:error, :compile_failed, reason}
    end
  end

  defp handle_error(:dependency, {:not_found, name}) do
    """
    # Error
    Package does not exist in remote repository

    The remote server (hex.pm unless overridden), does not contain #{name}
    Please check the spelling and try again.
    """
    |> Display.error()

    error(:package_not_found)
  end

  defp handle_error(:dependency, {reason, _name})
       when reason in [:no_connection, :bad_response] do
    """
    # Error
    Error getting package version from the remote repository.

    Talking to the remote repository (hex.pm unless overridden) failed.
    Please check your network connection and try again.
    """
    |> Display.error()

    error(:hex_api_error)
  end

  defp handle_error(:add_dependency, {:already_exists, name}) do
    """
    # Error
    Package already exists in wand.json

    Attempted to add #{name} to wand.json, but that name already exists.
    Did you mean to type wand upgrade #{name} instead?
    """
    |> Display.error()

    error(:package_already_exists)
  end

  defp handle_error(:download_failed, _reason) do
    """
    # Partial Success
    Unable to run mix deps.get

    The wand.json file was successfully updated,
    however mix deps.get failed.
    """
    |> Display.error()

    error(:install_deps_error)
  end

  defp handle_error(:compile_failed, _reason) do
    """
    # Partial Success
    Unable to run mix compile

    The wand.json file was successfully updated,
    however mix compile failed.
    """
    |> Display.error()

    error(:install_deps_error)
  end
end
