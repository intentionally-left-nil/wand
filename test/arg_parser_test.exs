defmodule ArgParserTest do
  use ExUnit.Case, async: true
  alias Wand.CLI.ArgParser
  alias Wand.CLI.Commands.Add.Package

  test "no arguments" do
    assert ArgParser.parse([]) == {:help, :help, :banner}
  end

  test "an unrecognized command is given" do
    assert ArgParser.parse(["wrong_command"]) == {:help, :help, {:unrecognized, "wrong_command"}}
  end

  test "--version" do
    assert ArgParser.parse(["--version"]) == {:version, []}
  end

  test "add shorthand" do
    assert ArgParser.parse(["a", "poison"]) == {:add, [%Package{name: "poison"}]}
  end

  test "remove shorthand" do
    assert ArgParser.parse(["r", "poison"]) == {:remove, ["poison"]}
  end

  test "upgrade shorthand" do
    assert ArgParser.parse(["u", "poison"]) == {:upgrade, {["poison"], :major}}
  end

  test "ok responses get converted to key, response" do
    assert ArgParser.parse(["version"]) == {:version, []}
  end

  test "error responses get converted to :help, key, reason" do
    assert ArgParser.parse(["init", "--wrong-flag"]) ==
             {:help, :init, {:invalid_flag, "--wrong-flag"}}
  end

  test "help is left untouched" do
    assert ArgParser.parse(["help", "add"]) == {:help, :add, :banner}
  end

  test "wand --verbose gives detailed help" do
    assert ArgParser.parse(["--verbose"]) == {:help, :help, :verbose}
  end

  test "wand --? gives detailed help" do
    assert ArgParser.parse(["--?"]) == {:help, :help, :verbose}
  end
end
