defmodule Wand.CLI.Commands.Remove do
  alias Wand.CLI.Display
  @behaviour Wand.CLI.Command
  @moduledoc """
  Remove elixir packages from wand.json

  ## Usage
  **wand** remove [package] [package]
  """
  def help(:missing_package) do
    """
    wand remove must be called with at least one package name.
    For example, wand remove poison.
    See wand help remove --verbose
    """
    |> Display.print()
  end
  def help(:banner), do: Display.print(@moduledoc)
  def help(:verbose), do: help(:banner)

  def validate(args) do
    {_switches, [_ | commands], _errors} = OptionParser.parse(args)

    case commands do
      [] -> {:error, :missing_package}
      names -> {:ok, names}
    end
  end
end
