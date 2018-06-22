defmodule Wand.CLI.Commands.Help do
  @behaviour Wand.CLI.Command

  def help(_type) do

  end
  def validate(["help", name]), do: {:help, String.to_atom(name), nil}
  def validate(_args), do: {:error, nil}
end
