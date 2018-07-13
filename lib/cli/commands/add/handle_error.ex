defmodule Wand.CLI.Commands.Add.Error do
  def handle_error(:package_not_found, name) do
    """
    # Error
    Package does not exist in remote repository

    The remote server (hex.pm unless overridden), does not contain #{name}
    Please check the spelling and try again.
    """
  end

  def handle_error(:hex_api_error, _reason) do
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
end
