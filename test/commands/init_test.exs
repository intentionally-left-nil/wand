defmodule InitTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.CLI.Commands.Init

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
      assert Init.validate(["init", "--overwrite", "--force"]) ==
               {:ok, {"./", [overwrite: true, force: true]}}
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
end
