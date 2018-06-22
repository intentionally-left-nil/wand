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

  describe "remove" do
    test "returns help if no args are given" do
      assert ArgParser.parse(["remove"]) == {:help, :remove, :missing_package}
    end

    test "returns an array of one package to remove" do
      assert ArgParser.parse(["remove", "poison"]) == {:remove, ["poison"]}
    end

    test "shorthand" do
      assert ArgParser.parse(["r", "poison"]) == {:remove, ["poison"]}
    end

    test "returns an array of multiple packages to remove" do
      assert ArgParser.parse(["remove", "poison", "ex_doc"]) == {:remove, ["poison", "ex_doc"]}
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

  describe "upgrade" do
    test "returns help if invalid flags are given" do
      assert ArgParser.parse(["upgrade", "poison", "--wrong-flag"]) ==
               {:help, :upgrade, {:invalid_flag, "--wrong-flag"}}
    end

    test "a single package" do
      assert ArgParser.parse(["upgrade", "poison"]) == {:upgrade, {["poison"], :major}}
    end

    test "a single package with the shorthand" do
      assert ArgParser.parse(["u", "poison"]) == {:upgrade, {["poison"], :major}}
    end

    test "--latest is the same as major" do
      assert ArgParser.parse(["upgrade", "poison", "--patch", "--latest"]) ==
               {:upgrade, {["poison"], :major}}
    end

    test "a single package to the next minor version" do
      assert ArgParser.parse(["upgrade", "poison", "--minor"]) == {:upgrade, {["poison"], :minor}}
    end

    test "a single package to the next patch version" do
      assert ArgParser.parse(["upgrade", "poison", "--patch"]) == {:upgrade, {["poison"], :patch}}
    end

    test "If both major and minor are passed in, prefer major" do
      assert ArgParser.parse(["upgrade", "poison", "--minor", "--major"]) ==
               {:upgrade, {["poison"], :major}}
    end

    test "upgrade multiple packages" do
      assert ArgParser.parse(["upgrade", "poison", "ex_doc", "--patch"]) ==
               {:upgrade, {["poison", "ex_doc"], :patch}}
    end

    test "upgrade all packages if none passed in" do
      assert ArgParser.parse(["upgrade", "--patch"]) == {:upgrade, {:all, :patch}}
    end
  end

  describe "outdated" do
    test "returns help when arguments are given" do
      assert ArgParser.parse(["outdated", "poison"]) == {:help, :outdated, :wrong_command}
    end
  end

  describe "init" do
    test "returns help if invalid flags are given" do
      assert ArgParser.parse(["init", "--wrong-flag"]) ==
               {:help, :init, {:invalid_flag, "--wrong-flag"}}
    end

    test "initializes the current path if no args are given" do
      assert ArgParser.parse(["init"]) == {:init, {"./", []}}
    end

    test "uses a custom path" do
      assert ArgParser.parse(["init", "../foo"]) == {:init, {"../foo", []}}
    end

    test "passes in overwrite" do
      assert ArgParser.parse(["init", "--overwrite"]) == {:init, {"./", [overwrite: true]}}
    end

    test "passes in task_only and force" do
      assert ArgParser.parse(["init", "--overwrite", "--task-only"]) ==
               {:init, {"./", [overwrite: true, task_only: true]}}
    end
  end
end
