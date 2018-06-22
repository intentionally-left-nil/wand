defmodule Wand.CLI.Display do
  @callback print(message :: String.t()) :: :ok

  def impl() do
    Application.get_env(:wand, :display, Wand.CLI.Display.Impl)
  end
end

defmodule Wand.CLI.Display.Impl do
  @behaviour Wand.CLI.Display
  def print(message) do
    IO.puts(message)
    :ok
  end
end
