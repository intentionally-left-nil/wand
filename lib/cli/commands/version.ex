defmodule Wand.CLI.Commands.Version do
  @behaviour Wand.CLI.Command

  def validate(_args), do: {:ok, []}
end
