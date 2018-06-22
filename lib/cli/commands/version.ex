defmodule Wand.CLI.Commands.Version do
  @behaviour Wand.CLI.Command

  def help(_type) do

  end

  def validate(_args), do: {:ok, []}
end
