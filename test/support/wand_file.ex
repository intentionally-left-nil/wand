defmodule Wand.Test.Helpers.WandFile do
  import Mox
  alias Wand.WandFile

  def stub_empty() do
    contents = %WandFile{} |> Poison.encode!()
    expect(Wand.FileMock, :read, fn _path -> {:ok, contents} end)
  end

  def stub_save(file) do
    contents = file |> Poison.encode!()
    expect(Wand.FileMock, :write, fn _path, ^contents -> :ok end)
  end

  def stub_no_file() do
    expect(Wand.FileMock, :read, fn _path -> {:error, :enoent} end)
  end
end
