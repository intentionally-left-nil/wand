defmodule Wand.CLI.Errors do
  @errors %{
    missing_wand_file: 64,
    invalid_wand_file: 65,
  }

  def error(key), do: {:error, Map.fetch!(@errors, key)}
end
