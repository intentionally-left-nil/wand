defmodule RemoveTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.CLI.Commands.Remove

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
end
