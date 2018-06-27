defmodule Wand.CLI.Errors do
  @errors %{
    missing_wand_file: 64,
  }

  def error(key), do: {:error, Map.fetch!(@errors, key)}
end
