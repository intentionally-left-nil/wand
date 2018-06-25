defmodule Wand.File do
  @callback read(path :: Path.t()) :: {:ok, binary()} | {:error, File.posix()}

  def impl() do
    Application.get_env(:wand, :file, File)
  end
end
