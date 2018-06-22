defmodule HelpTest do
  use ExUnit.Case, async: true
  alias Wand.CLI.Commands.Help

  describe "validate" do
    test "no args are given" do
      assert Help.validate([]) == {:error, nil}
    end

    test "the argument of help is given" do
      assert Help.validate(["help"]) == {:error, nil}
    end

    test "with --? passed in" do
      assert Help.validate(["--?"]) == {:error, nil}
    end

    test "help add" do
      assert Help.validate(["help", "add"]) == {:help, :add, nil}
    end
  end
end
