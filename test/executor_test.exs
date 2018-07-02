defmodule ExecutorTest do
  alias Wand.CLI.Executor
  alias Wand.CLI.Error
  alias Wand.Test.Helpers
  alias WandCore.WandFile
  use ExUnit.Case, async: true
  import Mox

  :verify_on_exit!
  Mox.defmock(TestCommand, for: Wand.CLI.Command)

  describe "Errors" do
    setup do
      Helpers.IO.stub_stderr()
      :ok
    end

    test ":missing_core if the core is not available" do
      stub_options([require_core: true])
      Helpers.System.stub_core_version_missing()
      assert Executor.run(TestCommand, :hello) == Error.get(:wand_core_missing)
    end

    test ":missing_wand_file when loading the file" do
      stub_options([load_wand_file: true])
      Helpers.WandFile.stub_no_file()
      assert Executor.run(TestCommand, :hello) == Error.get(:missing_wand_file)
    end

    test ":file_write_error when saving the file" do
      file = %WandFile{}
      stub_options()
      Helpers.WandFile.stub_cannot_save(file)
      expect(TestCommand, :execute, fn (:hello, %{}) -> {:ok, file} end)
      assert Executor.run(TestCommand, :hello) == Error.get(:file_write_error)
    end
  end

  test "execute calls the passed in module" do
    stub_options()
    stub_execute()
    expect(TestCommand, :options, fn() -> [] end)
    assert Executor.run(TestCommand, :hello) == :ok
  end

  test "Executes the command after the core is validated" do
    stub_options([require_core: true])
    stub_execute()
    Helpers.System.stub_core_version()
    assert Executor.run(TestCommand, :hello) == :ok
  end

  test "Passes in a wand_file" do
    stub_options([load_wand_file: true])
    stub_execute(%{wand_file: %WandFile{}})
    Helpers.WandFile.stub_load()
    assert Executor.run(TestCommand, :hello) == :ok
  end

  test "Saves a wand_file that is returned" do
    stub_options()
    file = %WandFile{}
    Helpers.WandFile.stub_save(file)
    expect(TestCommand, :execute, fn (:hello, %{}) -> {:ok, file} end)
    assert Executor.run(TestCommand, :hello) == :ok
  end

  defp stub_options(options \\ []) do
    expect(TestCommand, :options, fn() -> options end)
  end

  defp stub_execute(extras \\ %{}) do
    expect(TestCommand, :execute, fn (:hello, ^extras) -> :ok end)
  end

end
