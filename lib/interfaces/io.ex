defmodule Wand.Interfaces.IO do
  @callback puts(message :: String.t()) :: :ok

  def impl() do
    Application.get_env(:wand, :io, IO)
  end
end
