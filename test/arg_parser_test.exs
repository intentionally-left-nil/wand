defmodule ArgParserTest do
  use ExUnit.Case, async: true
  alias Wand.CLI.ArgParser
  alias Wand.CLI.Commands.Add.{Git, Hex, Package, Path}

  describe "help" do
    test "no args are given" do
      assert ArgParser.parse([]) == {:help, :help, nil}
    end

    test "the argument of help is given" do
      assert ArgParser.parse(["help"]) == {:help, :help, nil}
    end

    test "with --? passed in" do
      assert ArgParser.parse(["--?"]) == {:help, :help, nil}
    end

    test "an unrecognized command is given" do
      assert ArgParser.parse(["wrong_command"]) == {:help, {:unrecognized, "wrong_command"}}
    end

    test "help add" do
      assert ArgParser.parse(["help", "add"]) == {:help, :add, nil}
    end
  end

  describe "version" do
    test "wand --version returns the version" do
      assert ArgParser.parse(["--version"]) == {:version, []}
    end

    test "wand version returns the version" do
      assert ArgParser.parse(["version"]) == {:version, []}
    end
  end
end
