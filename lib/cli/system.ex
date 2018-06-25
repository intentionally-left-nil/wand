defmodule Wand.CLI.System do
  @callback halt(status :: integer()) :: no_return()

  def impl() do
    Application.get_env(:wand, :system, System)
  end
end
