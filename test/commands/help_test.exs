defmodule HelpTest do
  use ExUnit.Case, async: true
  alias Wand.CLI.Commands.Help

  describe "validate" do
    test "no args are given" do
      assert Help.validate([]) == {:error, :banner}
    end

    test "the argument of help is given" do
      assert Help.validate(["help"]) == {:error, :banner}
    end

    test "with --? passed in" do
      assert Help.validate(["--?"]) == {:error, :banner}
    end

    test "help add" do
      assert Help.validate(["help", "add"]) == {:help, :add, nil}
    end
  end
end
