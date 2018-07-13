defmodule Wand.CLI.WandFileWithHelp do
  @moduledoc false
  alias WandCore.WandFile
  alias Wand.CLI.Display
  alias Wand.CLI.Error

  def load() do
    case WandFile.load() do
      {:ok, file} -> {:ok, file}
      {:error, reason} -> {:error, :wand_file, {:load, reason}}
    end
  end

  def save(file) do
    case WandFile.save(file) do
      :ok -> :ok
      {:error, reason} -> {:error, :wand_file, {:save, reason}}
    end
  end

  def handle_error({:load, :json_decode_error}) do
    """
    # Error
    wand.json is not a valid JSON file.
    Please make sure you don't have any dangling commas or other invalid json.
    """
    |> Display.error()

    Error.get(:invalid_wand_file)
  end

  def handle_error({:load, reason})
      when reason in [:invalid_version, :missing_version, :version_mismatch] do
    """
    # Error
    The version field in wand.json is incorrect.

    Please make sure it is present and can be read by this version of the wand cli. You may need to upgrade wand to read this file.

    Detailed error: #{reason}
    """
    |> Display.error()

    Error.get(:invalid_wand_file)
  end

  def handle_error({:load, {:file_read_error, :eaccess}}) do
    """
    # Error
    Permission error reading wand.json.
    Please check to make sure the current user has read permissions, then try again.

    Detailed error: #{:file.format_error(:eaccess)}
    """
    |> Display.error()

    Error.get(:missing_wand_file)
  end

  def handle_error({:load, {:file_read_error, reason}}) do
    """
    # Error
    Could not find wand.json in the current directory.

    Make sure you are running wand from the root folder of your project, and that wand.json exists. If you are missing wand.json, type `wand init` to create one.

    Detailed error: #{:file.format_error(reason)}
    """
    |> Display.error()

    Error.get(:missing_wand_file)
  end

  def handle_error({:load, :invalid_dependencies}) do
    """
    # Error
    The version field in wand.json is incorrect.

    Either the key is missing, or it is not a map. Please edit the file, and then try again.
    """
    |> Display.error()

    Error.get(:invalid_wand_file)
  end

  def handle_error({:load, {:invalid_dependency, name}}) do
    """
    # Error
    A dependency in wand.json is formatted incorrectly.

    The dependency #{name} in wand.json is incorrect. Please fix it and try again.
    """
    |> Display.error()

    Error.get(:invalid_wand_file)
  end

  def handle_error({:save, reason}) do
    """
    # Error
    Could not write to wand.json

    Make sure you have permission to write to wand.json, otherwise see the detailed error for more information:

    Detailed error: #{:file.format_error(reason)}
    """
    |> Display.error()

    Error.get(:file_write_error)
  end
end
