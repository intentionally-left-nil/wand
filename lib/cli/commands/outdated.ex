defmodule Wand.CLI.Commands.Outdated do
  use Wand.CLI.Command
  alias Wand.CLI.Display

  @moduledoc """
  # Outdated
  List packages that are out of date.
  ### Usage
  wand outdated
  """

  @doc false
  def help(:wrong_command) do
    """
    wand outdated takes no arguments.
    Please enter just wand outdated
    """
    |> Display.print()
  end

  @doc false
  def help({:invalid_flag, flag}) do
    """
    #{flag} is invalid.
    Enter wand help outdated --verbose for more information
    """
    |> Wand.CLI.Display.print()
  end

  @doc false
  def help(_type), do: Display.print(@moduledoc)

  @doc false
  def validate(["outdated"]), do: {:ok, []}
  @doc false
  def validate(_args), do: {:error, :wrong_command}

  @doc false
  def execute([], %{}) do
    Wand.CLI.Mix.outdated()
    :ok
  end
end
