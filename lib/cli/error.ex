defmodule Wand.CLI.Error do
  @type key ::
          :missing_wand_file
          | :invalid_wand_file
          | :package_not_found
          | :package_already_exists
          | :hex_api_error
          | :file_write_error
          | :install_deps_error
          | :file_already_exists
          | :wand_core_api_error
          | :mix_file_not_updated
          | :wand_core_missing
          | :bad_wand_core_version
  @type t :: integer()

  @errors %{
    missing_wand_file: 64,
    invalid_wand_file: 65,
    package_not_found: 66,
    package_already_exists: 67,
    hex_api_error: 68,
    file_write_error: 69,
    install_deps_error: 70,
    file_already_exists: 71,
    wand_core_api_error: 72,
    mix_file_not_updated: 73,
    wand_core_missing: 74,
    bad_wand_core_version: 75
  }

  @moduledoc """
  When the CLI has an error, it will return a status code indicative of the type of error that occured.
  This can be used for scripting. These exit codes are guaranteed to be the same only within the same major version.

  The current error codes are as follows:
  ```
  %{
    missing_wand_file: 64,
    invalid_wand_file: 65,
    package_not_found: 66,
    package_already_exists: 67,
    hex_api_error: 68,
    file_write_error: 69,
    install_deps_error: 70,
    file_already_exists: 71,
    wand_core_api_error: 72,
    mix_file_not_updated: 73,
    wand_core_missing: 74,
    bad_wand_core_version: 75
  }
  ```
  """

  @spec code(key) :: t
  def code(key), do: Map.fetch!(@errors, key)

  @spec get(key) :: {:error, t}
  def get(key), do: {:error, code(key)}
end
