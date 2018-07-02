defmodule ExecutorTest do
  alias Wand.CLI.Executor
  alias Wand.CLI.Error
  alias Wand.Test.Helpers
  use ExUnit.Case, async: true
  import Mox

  :verify_on_exit!
  Mox.defmock(TestCommand, for: Wand.CLI.Command)

  test "execute calls the passed in module" do
    stub_options([])
    stub_execute()
    expect(TestCommand, :options, fn() -> [] end)
    assert Executor.run(TestCommand, :hello) == :ok
  end

  test ":missing_core if the core is not available" do
    stub_options([require_core: true])
    Helpers.System.stub_core_version_missing()
    Helpers.IO.stub_stderr()
    assert Executor.run(TestCommand, :hello) == Error.get(:wand_core_missing)
  end

  test "Executes the command after the core is validated" do
    stub_options([require_core: true])
    stub_execute()
    Helpers.System.stub_core_version()
    assert Executor.run(TestCommand, :hello) == :ok
  end

  defp stub_options(options) do
    expect(TestCommand, :options, fn() -> options end)
  end

  defp stub_execute() do
    expect(TestCommand, :execute, fn :hello -> :ok end)
  end

end
