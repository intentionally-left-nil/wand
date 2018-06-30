defmodule Wand.CLI.Commands.Version do
  alias Wand.CLI.Display
  @io Wand.Interfaces.IO.impl()
  @version Mix.Project.config() |> Keyword.get(:version, "unknown")
  @behaviour Wand.CLI.Command
  @moduledoc """
  Get the installed version of wand and wand-core

  ## Usage
  **wand** version
  """

  def help(:banner), do: Display.print(@moduledoc)
  def help(:verbose), do: help(:banner)

  def validate(_args), do: {:ok, []}

  def execute(_args) do
    @io.puts(@version)
    :ok
  end
end
