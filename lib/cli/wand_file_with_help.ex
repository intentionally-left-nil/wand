defmodule Wand.CLI.WandFileWithHelp do
  alias Wand.WandFile
  alias Wand.CLI.Display
  import Wand.CLI.Errors, only: [error: 1]

  def load() do
    case WandFile.load() do
      {:ok, file} -> {:ok, file}
      {:error, reason} -> {:error, :wand_file_load, reason}
    end
  end

  def save(file) do
    case WandFile.save(file) do
      :ok -> :ok
      {:error, reason} -> {:error, :wand_file_save, reason}
    end
  end

  def handle_error(:wand_file_load, :json_decode_error) do
    """
    # Error
    wand.json is not a valid JSON file.
    Please make sure you don't have any dangling commas or other invalid json.
    """
    |> Display.error()

    error(:invalid_wand_file)
  end

  def handle_error(:wand_file_load, reason)
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

  def handle_error(:wand_file_load, {:file_read_error, :eaccess}) do
    """
    # Error
    Permission error reading wand.json.
    Please check to make sure the current user has read permissions, then try again.

    Detailed error: #{:file.format_error(:eaccess)}
    """
    |> Display.error()

    error(:missing_wand_file)
  end

  def handle_error(:wand_file_load, {:file_read_error, reason}) do
    """
    # Error
    Could not find wand.json in the current directory.

    Make sure you are running wand from the root folder of your project, and that wand.json exists. If you are missing wand.json, type `wand init` to create one.

    Detailed error: #{:file.format_error(reason)}
    """
    |> Display.error()

    error(:missing_wand_file)
  end

  def handle_error(:wand_file_load, :invalid_dependencies) do
    """
    # Error
    The version field in wand.json is incorrect.

    Either the key is missing, or it is not a map. Please edit the file, and then try again.
    """
    |> Display.error()

    error(:invalid_wand_file)
  end

  def handle_error(:wand_file_load, {:invalid_dependency, name}) do
    """
    # Error
    A dependency in wand.json is formatted incorrectly.

    The dependency #{name} in wand.json is incorrect. Please fix it and try again.
    """
    |> Display.error()

    error(:invalid_wand_file)
  end

  def handle_error(:wand_file_save, reason) do
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
