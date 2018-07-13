defmodule ExecutorTest do
  alias Wand.CLI.Executor
  alias Wand.CLI.Executor.Result
  alias Wand.CLI.Error
  alias Wand.Test.Helpers
  alias WandCore.WandFile
  use ExUnit.Case, async: true
  import Mox

  setup :verify_on_exit!

  Mox.defmock(TestCommand, for: Wand.CLI.Command)

  describe "Errors" do
    setup do
      Helpers.IO.stub_stderr()
      :ok
    end

    test ":missing_core if the core is not available" do
      stub_options(require_core: true)
      Helpers.System.stub_core_version_missing()
      assert Executor.run(TestCommand, :hello) == Error.get(:wand_core_missing)
    end

    test ":missing_wand_file when loading the file" do
      stub_options(load_wand_file: true)
      Helpers.WandFile.stub_no_file()
      assert Executor.run(TestCommand, :hello) == Error.get(:missing_wand_file)
    end

    test ":file_write_error when saving the file" do
      file = %WandFile{}
      stub_options()
      Helpers.WandFile.stub_cannot_save(file)
      stub_execute_return_wandfile()
      assert Executor.run(TestCommand, :hello) == Error.get(:file_write_error)
    end
  end

  test ":hex_api_error when returned by execute" do
    stub_options()
    stub_handle_error(:hex_api_error)
    Helpers.IO.stub_stderr()
    expect(TestCommand, :execute, fn :hello, %{} -> {:error, :hex_api_error, nil} end)
    assert Executor.run(TestCommand, :hello) == Error.get(:hex_api_error)
  end

  test "Returns an error from after_save" do
    stub_options()
    file = %WandFile{}
    Helpers.WandFile.stub_save(file)
    stub_execute_return_wandfile()
    stub_handle_error(:wand_core_api_error)
    Helpers.IO.stub_stderr()
    expect(TestCommand, :after_save, fn :hello -> {:error, :wand_core_api_error, nil} end)
    assert Executor.run(TestCommand, :hello) == Error.get(:wand_core_api_error)
  end

  describe "Successfully" do
    setup do
      Helpers.IO.stub_io()
      :ok
    end

    test "execute calls the passed in module" do
      stub_options()
      stub_execute()
      assert Executor.run(TestCommand, :hello) == :ok
    end

    test "Executes the command after the core is validated" do
      stub_options(require_core: true)
      stub_execute()
      Helpers.System.stub_core_version()
      assert Executor.run(TestCommand, :hello) == :ok
    end

    test "Passes in a wand_file" do
      stub_options(load_wand_file: true)
      stub_execute(%{wand_file: %WandFile{}})
      Helpers.WandFile.stub_load()
      assert Executor.run(TestCommand, :hello) == :ok
    end

    test "Saves a wand_file that is returned, and calls after_save" do
      stub_options()
      file = %WandFile{}
      Helpers.WandFile.stub_save(file)
      stub_execute_return_wandfile()
      expect(TestCommand, :after_save, fn :hello -> :ok end)
      assert Executor.run(TestCommand, :hello) == :ok
    end

    test "saves a wand_file to a custom path" do
      stub_options()
      file = %WandFile{}
      Helpers.WandFile.stub_save(file, "/tmp/wand.json")
      expect(TestCommand, :execute, fn :hello, %{} -> {:ok, %Result{wand_file: %WandFile{}, wand_path: "/tmp/wand.json"}} end)
      expect(TestCommand, :after_save, fn :hello -> :ok end)
      assert Executor.run(TestCommand, :hello) == :ok
    end
  end

  test "skips printing if the message is nil" do
    stub_options()
    expect(TestCommand, :execute, fn :hello, %{} -> {:ok, %Result{message: nil}} end)
    assert Executor.run(TestCommand, :hello) == :ok
  end

  defp stub_options(options \\ []) do
    expect(TestCommand, :options, fn -> options end)
  end

  defp stub_execute(extras \\ %{}) do
    expect(TestCommand, :execute, fn :hello, ^extras -> {:ok, %Result{}} end)
  end

  defp stub_execute_return_wandfile() do
    expect(TestCommand, :execute, fn :hello, %{} -> {:ok, %Result{wand_file: %WandFile{}}} end)
  end

  defp stub_handle_error(exit_code) do
    expect(TestCommand, :handle_error, fn ^exit_code, _data -> "so sad" end)
  end
end
