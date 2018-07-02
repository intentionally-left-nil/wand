defmodule ExecutorTest do
  alias Wand.CLI.Executor
  use ExUnit.Case, async: true
  import Mox

  :verify_on_exit!

  test "execute calls the passed in module" do
    Mox.defmock(TestCommand, for: Wand.CLI.Command)
    expect(TestCommand, :execute, fn :hello -> :ok end)
    assert Executor.run(TestCommand, :hello) == :ok
  end
end
