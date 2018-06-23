defmodule Wand.CLI.Commands.Help do
  alias Wand.CLI.Display
  @behaviour Wand.CLI.Command
  def help(:banner) do
    """

    Usage: wand [command] [flags]

    Available commands:

    add         Add dependencies to your project
    help        Get detailed help
    init        Add the global wand tasks needed to use wand
    outdated    See the list of packages that are out of date
    remove      Remove dependencies from your project
    upgrade     Upgrade a dependency in your project
    version     Get the version of wand installed on the system

    You can type `**wand help**` [command] to see more information.

    Options:

    --version   Get the version of wand installed on the system
    """
    |> Display.print()
  end

  def validate(["help", name]), do: {:help, String.to_atom(name), nil}
  def validate(_args), do: {:error, :banner}
end
