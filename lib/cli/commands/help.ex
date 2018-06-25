defmodule Wand.CLI.Commands.Help do
  alias Wand.CLI.Display
  @behaviour Wand.CLI.Command

  @moduledoc """
  Displays detailed help documentation for wand
  ## Usage
  **wand** help [command]

  ## Available commands
  <pre>
  add         Add dependencies to your project
  help        Get detailed help
  init        Add the global wand tasks needed to use wand
  outdated    See the list of packages that are out of date
  remove      Remove dependencies from your project
  upgrade     Upgrade a dependency in your project
  version     Get the version of wand installed on the system
  </pre>

  ## Options
  <pre>
  --verbose   Detailed help for every command
  --?         Same as --verbose
  </pre>
  """

  def help(:banner), do: Display.print(Wand.banner())
  def help(:verbose), do: Display.print(@moduledoc)
  def help({:invalid_flag, flag}) do
    """
    # Error
    `#{flag}` is not a valid flag for help.
    Valid flags are:
    --verbose   Detailed help for every command
    --?         Same as --verbose
    """
    |> Display.print()
  end

  def help({:unrecognized, command}) do
    """
    # Error
    `#{command}` is not a recognized command.
    Type **wand help --verbose** for more information.
    """
    |> Display.print()
  end

  def validate(args) do
    flags = [
      verbose: :boolean,
      "?": :boolean,
    ]
    {switches, [_ | commands], errors} = OptionParser.parse(args, strict: flags)

    case Wand.CLI.Command.parse_errors(errors) do
      :ok -> parse(commands, verbose?(switches))
      error -> error
    end
  end

  defp parse(["help"], _verbose), do: {:error, :verbose}
  defp parse([name], _verbose=true), do: {:help, String.to_atom(name), :verbose}
  defp parse([name], _verbose=false), do: {:help, String.to_atom(name), :banner}
  defp parse(_commands, _verbose=true), do: {:error, :verbose}
  defp parse(_commands, _verbose=false), do: {:error, :banner}

  defp verbose?(switches) do
    cond do
      Keyword.get(switches, :verbose) -> true
      Keyword.get(switches, :"?") -> true
      true -> false
    end
  end
end
