defmodule Wand.CLI.ArgParser do
  def parse(args) do
    case OptionParser.parse(args) do
      _ -> {:help, nil}
    end
  end
end
