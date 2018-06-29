defmodule WandCore.Interfaces.File do
  @callback read(path :: Path.t()) :: {:ok, binary()} | {:error, File.posix()}
  @callback write(path :: Path.t(), contents :: iodata()) :: :ok | {:error, File.posix()}
  @callback exists?(path :: Path.t()) :: boolean()

  def impl() do
    Application.get_env(:wand, :file, File)
  end
end
