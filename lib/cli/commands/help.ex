defmodule Wand.CLI.Commands.Help do
  alias Wand.CLI.Display
  @behaviour Wand.CLI.Command

  def help(:banner), do: Display.print(Wand.banner())

  def validate(["help", name]), do: {:help, String.to_atom(name), nil}
  def validate(_args), do: {:error, :banner}
end
