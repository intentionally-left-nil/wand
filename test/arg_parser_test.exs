defmodule Wand.CLI.ArgParserTest do
  use ExUnit.Case

  describe "help" do
    test "no args are given" do
      assert Wand.CLI.ArgParser.parse([]) == {:help, nil}
    end

    test "the argument of help is given" do
      assert Wand.CLI.ArgParser.parse(["help"]) == {:help, nil}
    end

    test "with --? passed in" do
      assert Wand.CLI.ArgParser.parse(["--?"]) == {:help, nil}
    end

    test "an unrecognized command is given" do
      assert Wand.CLI.ArgParser.parse(["wrong_command"]) ==
               {:help, {:unrecognized, "wrong_command"}}
    end
  end

  describe "add" do
    test "returns help if no args are given" do
      assert Wand.CLI.ArgParser.parse(["add"]) == {:help, {:add, :missing_package}}
    end

    test "a simple package" do
      assert Wand.CLI.ArgParser.parse(["add", "poison"]) ==
               {:add, [%Wand.CLI.Commands.Add.Args{package: "poison"}]}
    end

    test "a package with a specific version" do
      assert Wand.CLI.ArgParser.parse(["add", "poison@3.1"]) ==
               {:add, [%Wand.CLI.Commands.Add.Args{package: "poison", version: "3.1"}]}
    end
  end
end
