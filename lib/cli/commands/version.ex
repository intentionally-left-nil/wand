defmodule Wand.CLI.Commands.Version do
  alias Wand.CLI.Display
  @io Wand.Interfaces.IO.impl()
  @behaviour Wand.CLI.Command
  @moduledoc """
  Get the installed version of wand. To get the version of wand_core, use wand core version instead.

  ## Usage
  **wand** version
  """

  def help(:banner), do: Display.print(@moduledoc)
  def help(:verbose), do: help(:banner)

  def validate(_args), do: {:ok, []}

  def execute(_args) do
    @io.puts(Wand.version())
    :ok
  end
end
