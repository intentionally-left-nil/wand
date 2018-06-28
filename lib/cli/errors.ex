defmodule Wand.CLI.Errors do
  @errors %{
    missing_wand_file: 64,
    invalid_wand_file: 65,
    package_not_found: 66,
    package_already_exists: 67,
    hex_api_error: 68,
  }

  def code(key), do: Map.fetch!(@errors, key)
  def error(key), do: {:error, code(key)}
end
