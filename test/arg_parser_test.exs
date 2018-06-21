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
      assert Wand.CLI.ArgParser.parse(["wrong_command"]) == {:help, {:unrecognized, "wrong_command"}}
    end
  end
end
