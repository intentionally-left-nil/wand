defmodule Wand.CLI.Errors do
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
  }

  def code(key), do: Map.fetch!(@errors, key)
  def error(key), do: {:error, code(key)}
end
