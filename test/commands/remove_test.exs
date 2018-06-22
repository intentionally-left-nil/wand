defmodule RemoveTest do
  use ExUnit.Case, async: true
  alias Wand.CLI.Commands.Remove

  describe "validate" do
    test "returns help if no args are given" do
      assert Remove.validate(["remove"]) == {:error, :missing_package}
    end

    test "returns an array of one package to remove" do
      assert Remove.validate(["remove", "poison"]) == {:ok, ["poison"]}
    end

    test "shorthand" do
      assert Remove.validate(["r", "poison"]) == {:ok, ["poison"]}
    end

    test "returns an array of multiple packages to remove" do
      assert Remove.validate(["remove", "poison", "ex_doc"]) == {:ok, ["poison", "ex_doc"]}
    end
  end
end
