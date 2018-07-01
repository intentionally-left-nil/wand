defmodule Wand.CLI.Commands.Outdated do
  @behaviour Wand.CLI.Command
  alias Wand.CLI.Display

  @moduledoc """
  List packages that are out of date.
  ## Usage
  wand outdated
  """

  def help(:wrong_command) do
    """
    wand outdated takes no arguments.
    Please enter just wand outdated
    """
    |> Display.print()
  end

  def help({:invalid_flag, flag}) do
    """
    #{flag} is invalid.
    Enter wand help outdated --verbose for more information
    """
    |> Wand.CLI.Display.print()
  end

  def help(_type), do: Display.print(@moduledoc)

  def validate(["outdated"]), do: {:ok, []}
  def validate(_args), do: {:error, :wrong_command}

  def execute([]) do
    Wand.CLI.Mix.outdated()
    :ok
  end
end
