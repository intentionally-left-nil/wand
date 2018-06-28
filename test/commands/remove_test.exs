defmodule RemoveTest do
  use ExUnit.Case, async: true
  import Mox
  import Wand.CLI.Errors, only: [error: 1]
  alias Wand.CLI.Commands.Remove
  alias Wand.Test.Helpers

  describe "validate" do
    test "returns help if no args are given" do
      assert Remove.validate(["remove"]) == {:error, :missing_package}
    end

    test "returns an array of one package to remove" do
      assert Remove.validate(["remove", "poison"]) == {:ok, ["poison"]}
    end

    test "returns an array of multiple packages to remove" do
      assert Remove.validate(["remove", "poison", "ex_doc"]) == {:ok, ["poison", "ex_doc"]}
    end
  end

  describe "help" do
    setup :verify_on_exit!
    setup :stub_io

    test "missing_package" do
      Remove.help(:missing_package)
    end

    test "banner" do
      Remove.help(:banner)
    end

    test "verbose" do
      Remove.help(:verbose)
    end

    def stub_io(_) do
      expect(Wand.IOMock, :puts, fn _message -> :ok end)
      :ok
    end
  end

  describe "execute" do
    test "Error reading the WandFile" do
      Helpers.WandFile.stub_no_file()
      Helpers.IO.stub_stderr()
      assert Remove.execute(["poison"]) == error(:missing_wand_file)
    end
  end
end
