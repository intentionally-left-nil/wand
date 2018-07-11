defmodule Wand.CLI.Commands.Add.Error do
  def handle_error(:package_not_found, name) do
    """
    # Error
    Package does not exist in remote repository

    The remote server (hex.pm unless overridden), does not contain #{name}
    Please check the spelling and try again.
    """
  end

  def handle_error(:hex_api_error, reason) do
    """
    # Error
    Error getting package version from the remote repository.

    Talking to the remote repository (hex.pm unless overridden) failed.
    Please check your network connection and try again.
    """
  end

  def handle_error(:package_already_exists, name) do
    """
    # Error
    Dependency already exists in wand.json

    Attempted to add #{name} to wand.json, but that package already exists.
    Did you mean to type wand upgrade #{name} instead?
    """
  end

  def handle_error(:install_deps_error, :download_failed) do
    """
    # Partial Success
    Unable to run mix deps.get

    The wand.json file was successfully updated,
    however mix deps.get failed.
    """
  end

  def handle_error(:install_deps_error, :compile_failed) do
    """
    # Partial Success
    Unable to run mix compile

    The wand.json file was successfully updated,
    however mix compile failed.
    """
    |> Display.error()
  end
end
