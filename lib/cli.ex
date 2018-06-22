defmodule Wand.CLI do
  @system Wand.CLI.System.impl()
  def main(args) do
    Wand.CLI.ArgParser.parse(args)
    |> route
  end

  defp route({:help, key, data}) do
    Wand.CLI.Command.route(key, :help, [data])
    @system.halt(1)
  end

end
