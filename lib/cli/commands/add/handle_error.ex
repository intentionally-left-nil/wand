defmodule Wand.CLI.Commands.Add.Error do
  def handle(:dependency, {:not_found, name}) do
    """
    # Error
    Package does not exist in remote repository

    The remote server (hex.pm unless overridden), does not contain #{name}
    Please check the spelling and try again.
    """
    |> Display.error()

    Error.get(:package_not_found)
  end

  def handle_error(:dependency, {reason, _name})
       when reason in [:no_connection, :bad_response] do
    """
    # Error
    Error getting package version from the remote repository.

    Talking to the remote repository (hex.pm unless overridden) failed.
    Please check your network connection and try again.
    """
    |> Display.error()

    Error.get(:hex_api_error)
  end

  def handle_error(:add_dependency, {:already_exists, name}) do
    """
    # Error
    Dependency already exists in wand.json

    Attempted to add #{name} to wand.json, but that package already exists.
    Did you mean to type wand upgrade #{name} instead?
    """
    |> Display.error()

    Error.get(:package_already_exists)
  end

  def handle_error(:download_failed, _reason) do
    """
    # Partial Success
    Unable to run mix deps.get

    The wand.json file was successfully updated,
    however mix deps.get failed.
    """
    |> Display.error()

    Error.get(:install_deps_error)
  end

  def handle_error(:compile_failed, _reason) do
    """
    # Partial Success
    Unable to run mix compile

    The wand.json file was successfully updated,
    however mix compile failed.
    """
    |> Display.error()

    Error.get(:install_deps_error)
  end
end
