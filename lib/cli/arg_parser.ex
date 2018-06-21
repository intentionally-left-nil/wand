defmodule Wand.CLI.ArgParser do
  def parse(args) do
    {_, main_commands, _} = OptionParser.parse(args)
    case main_commands do
      [] -> {:help, nil}
      ["help"] -> {:help, nil}
      [command | _rest] -> {:help, {:unrecognized, command}}
    end
  end
end
