defmodule Wand.Test.Helpers.IO do
  import Mox

  def stub_io() do
    expect(Wand.IOMock, :puts, fn _message -> :ok end)
  end

  def stub_stderr() do
    expect(Wand.IOMock, :puts, fn :stderr, _message -> :ok end)
  end
end
