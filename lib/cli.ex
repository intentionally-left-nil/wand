defmodule Wand.CLI do
  @system Wand.Interfaces.System.impl()
  def main(args) do
    Wand.CLI.ArgParser.parse(args)
    |> route
  end

  defp route({key, data}) do
    case Wand.CLI.Command.route(key, :execute, [data]) do
      :ok -> :ok
      {:error, code} -> @system.halt(code)
    end
  end

  defp route({:help, key, data}) do
    Wand.CLI.Command.route(key, :help, [data])
    @system.halt(1)
  end
end
