defmodule Wand.CLI.Errors do
  @errors %{
    missing_wand_file: 64,
    invalid_wand_file: 65,
    package_not_found: 66,
    hex_api_error: 67,
  }

  def code(key), do: Map.fetch!(@errors, key)
  def error(key), do: {:error, code(key)}
end
