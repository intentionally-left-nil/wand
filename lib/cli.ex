defmodule Wand.CLI do
  def main(args) do
    Wand.CLI.ArgParser.parse(args)
    |> IO.inspect()
  end
end
