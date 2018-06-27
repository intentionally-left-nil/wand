defmodule Wand.CLI.Commands.Add.Execute do
  alias Wand.CLI.Commands.Add.Package
  alias Wand.WandFile
  alias Wand.WandFile.Dependency
  alias Wand.CLI.Display
  import Wand.CLI.Errors, only: [error: 1]

  def execute(packages) do
    with \
      {:ok, file} <- load_file(),
      {:ok, dependencies} <- get_dependencies(packages)
    do
      dependencies
      |> Enum.reduce(file, fn (dependency, file) ->
         WandFile.add(file, dependency) |> elem(1)
       end)
      |> WandFile.save()
    else
      {:error, step, reason} -> handle_error(step, reason)
    end
  end

  defp get_dependencies(packages) do
    dependencies = packages
    |> Enum.map(&Task.async(fn -> get_dependency(&1) end))
    |> Enum.map(&Task.await/1)

    case Enum.find(dependencies, &(elem(&1, 0) == :error)) do
      nil -> {:ok, Enum.unzip(dependencies) |> elem(1)}
      {:error, error} -> {:error, :dependency, error}
    end
  end

  defp get_dependency(%Package{name: name, requirement: :latest}=package) do
    case Wand.Hex.releases(name) do
      {:ok, [version | _]} ->
        requirement = get_requirement(version, package.mode)
        {:ok, %Dependency{name: name, requirement: requirement}}
      {:error, error} -> {:error, {error, name}}
    end
  end

  defp get_requirement(version, :normal) do
    "~> " <> version
  end

  defp load_file() do
    case WandFile.load() do
      {:ok, file} -> {:ok, file}
      {:error, reason} -> {:error, :wand_file_read, reason}
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

  defp handle_error(:wand_file_read, reason) when reason in [:invalid_version, :missing_version, :version_mismatch] do
    """
    # Error
    The version field in wand.json is incorrect.

    Please make sure it is present and can be read by this version of the wand cli. You may need to upgrade wand to read this file.

    Detailed error: #{reason}
    """
    |> Display.error()
    error(:invalid_wand_file)
  end

  defp handle_error(:wand_file_read, {:file_read_error, :eacces}) do
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
end
