defmodule InitTest do
  use ExUnit.Case, async: true
  import Mox
  import Wand.CLI.Errors, only: [error: 1]
  alias Wand.CLI.Commands.Init
  alias Wand.Test.Helpers
  alias Wand.WandFile

  describe "validate" do
    test "returns help if invalid flags are given" do
      assert Init.validate(["init", "--wrong-flag"]) == {:error, {:invalid_flag, "--wrong-flag"}}
    end

    test "initializes the current path if no args are given" do
      assert Init.validate(["init"]) == {:ok, {"./", []}}
    end

    test "uses a custom path" do
      assert Init.validate(["init", "../foo"]) == {:ok, {"../foo", []}}
    end

    test "passes in overwrite" do
      assert Init.validate(["init", "--overwrite"]) == {:ok, {"./", [overwrite: true]}}
    end

    test "passes in force" do
      assert Init.validate(["init", "--overwrite"]) ==
               {:ok, {"./", [overwrite: true]}}
    end
  end

  describe "help" do
    setup :verify_on_exit!
    setup :stub_io

    test "invalid flag" do
      Init.help({:invalid_flag, "--wrong-flag"})
    end

    test "banner" do
      Init.help(:banner)
    end

    test "verbose" do
      Init.help(:verbose)
    end

    def stub_io(_) do
      expect(Wand.IOMock, :puts, fn _message -> :ok end)
      :ok
    end
  end

  describe "execute fails" do
    setup do
      Helpers.IO.stub_stderr()
      :ok
    end

    test ":file_already_exists when the file already exists" do
      stub_exists("wand.json", true)
      assert Init.execute({"wand.json", []}) == error(:file_already_exists)
    end

    test ":file_write_error when saving the file" do
      stub_exists("wand.json", false)
      Helpers.WandFile.stub_cannot_save(%WandFile{})
      assert Init.execute({"wand.json", []}) == error(:file_write_error)
    end

    defp stub_exists(path, exists) do
      expect(Wand.FileMock, :exists?, fn ^path -> exists end)
    end
  end
end
