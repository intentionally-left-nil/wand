defmodule Wand.CLI.Commands.Outdated do
  @behaviour Wand.CLI.Command

  def help(_type) do

  end

  def validate([]), do: {:ok, []}
  def validate(_args), do: {:error, :wrong_command}
end
