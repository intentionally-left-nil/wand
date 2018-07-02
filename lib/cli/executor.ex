defmodule Wand.CLI.Executor do
  def run(module, data) do
    module.execute(data)
  end
end
