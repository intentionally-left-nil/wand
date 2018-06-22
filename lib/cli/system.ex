defmodule Wand.CLI.System do
  @callback halt(status :: integer()) :: no_return()
end
