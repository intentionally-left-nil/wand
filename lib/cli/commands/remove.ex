defmodule Wand.CLI.Commands.Remove do
  @behaviour Wand.CLI.Command

  def help(_type) do

  end

  def validate(args) do
    {_switches, [_ | commands], _errors} = OptionParser.parse(args)

    case commands do
      [] -> {:error, :missing_package}
      names -> {:ok, names}
    end
  end
end
