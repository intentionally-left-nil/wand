defmodule Wand.CLI.Executor do
  def run(module, data) do
    Kernel.apply(module, :execute, [data])
  end
end
