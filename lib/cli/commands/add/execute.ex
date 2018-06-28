defmodule Wand.CLI.Commands.Add.Execute do
  alias Wand.CLI.Commands.Add.Package
  alias Wand.WandFile
  alias Wand.WandFile.Dependency
  alias Wand.CLI.Display
  import Wand.CLI.Errors, only: [error: 1]

  def execute(packages) do
    with {:ok, file} <- load_file(),
         {:ok, dependencies} <- get_dependencies(packages),
         {:ok, file} <- add_dependencies(file, dependencies),
         :ok <- save_file(file) do
      :ok
    else
      {:error, step, reason} -> handle_error(step, reason)
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

  defp load_file() do
    case WandFile.load() do
      {:ok, file} -> {:ok, file}
      {:error, reason} -> {:error, :wand_file_read, reason}
    end
  end

  defp save_file(file) do
    case WandFile.save(file) do
      :ok -> :ok
      {:error, reason} -> {:error, :wand_file_write, reason}
    end
  end

  defp handle_error(:wand_file_read, :json_decode_error) do
    """
    # Error
    wand.json is not a valid JSON file.
    Please make sure you don't have any dangling commas or other invalid json.
    """
    |> Display.error()

    error(:invalid_wand_file)
  end

  defp handle_error(:wand_file_read, reason)
       when reason in [:invalid_version, :missing_version, :version_mismatch] do
    """
    # Error
    The version field in wand.json is incorrect.

    Please make sure it is present and can be read by this version of the wand cli. You may need to upgrade wand to read this file.

    Detailed error: #{reason}
    """
    |> Display.error()

    error(:invalid_wand_file)
  end

  defp handle_error(:wand_file_read, {:file_read_error, :eaccess}) do
    """
    # Error
    Permission error reading wand.json.
    Please check to make sure the current user has read permissions, then try again.

    Detailed error: #{:file.format_error(:eaccess)}
    """
    |> Display.error()

    error(:missing_wand_file)
  end

  defp handle_error(:wand_file_read, {:file_read_error, reason}) do
    """
    # Error
    Could not find wand.json in the current directory.

    Make sure you are running `wand add` from the root folder of your project, and that wand.json exists. If you are missing wand.json, type `wand init` to create one.

    Detailed error: #{:file.format_error(reason)}
    """
    |> Display.error()

    error(:missing_wand_file)
  end

  defp handle_error(:wand_file_read, :invalid_dependencies) do
    """
    # Error
    The version field in wand.json is incorrect.

    Either the key is missing, or it is not a map. Please edit the file, and then re-run wand add.
    """
    |> Display.error()

    error(:invalid_wand_file)
  end

  defp handle_error(:wand_file_read, {:invalid_dependency, name}) do
    """
    # Error
    A dependency in wand.json is formatted incorrectly.

    The dependency #{name} in wand.json is incorrect. Please fix it and try again.
    """
    |> Display.error()

    error(:invalid_wand_file)
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

  defp handle_error(:wand_file_write, reason) do
    """
    # Error
    Could not write to wand.json

    Make sure you have permission to write to wand.json, otherwise see the detailed error for more information:

    Detailed error: #{:file.format_error(reason)}
    """
    |> Display.error()

    error(:file_write_error)
  end
end
