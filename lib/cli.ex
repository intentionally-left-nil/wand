defmodule Wand.CLI do
  alias Wand.CLI.Display
  alias Wand.CLI.Executor
  @system Wand.Interfaces.System.impl()
  @moduledoc """
  The main entrypoint for the wand escript
  See `Wand` for more information
  """
  @spec main([String.t()]) :: :ok | no_return()
  def main(args) do
    Wand.CLI.ArgParser.parse(args)
    |> route
  end

  defp route({key, data}) do
    module = Wand.CLI.Command.get_module(key)

    case Executor.run(module, data) do
      :ok ->
        Display.success("Succeeded!")
        :ok

      {:ok, :silent} ->
        :ok

      {:ok, message} ->
        Display.success(message)
        :ok

      {:error, code} ->
        @system.halt(code)
    end
  end

  defp route({:help, key, data}) do
    module = Wand.CLI.Command.get_module(key)
    module.help(data)
    @system.halt(1)
  end
end
