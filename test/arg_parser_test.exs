defmodule Wand.CLI.ArgParserTest do
  use ExUnit.Case

  describe "help" do
    test "no args are given" do
      assert Wand.CLI.ArgParser.parse([]) == {:help, nil, nil}
    end

    test "the argument of help is given" do
      assert Wand.CLI.ArgParser.parse(["help"]) == {:help, nil, nil}
    end

    test "with --? passed in" do
      assert Wand.CLI.ArgParser.parse(["--?"]) == {:help, nil, nil}
    end

    test "an unrecognized command is given" do
      assert Wand.CLI.ArgParser.parse(["wrong_command"]) ==
               {:help, {:unrecognized, "wrong_command"}}
    end
  end

  describe "add" do
    test "returns help if no args are given" do
      assert Wand.CLI.ArgParser.parse(["add"]) == {:help, :add, :missing_package}
    end

    test "returns help if invalid flags are given" do
      assert Wand.CLI.ArgParser.parse(["add", "poison", "--wrong-flag"]) == {:help, :add, {:invalid_flag, "--wrong-flag"}}
    end

    test "a simple package" do
      assert Wand.CLI.ArgParser.parse(["add", "poison"]) ==
               {:add, [%Wand.CLI.Commands.Add.Package{name: "poison"}]}
    end

    test "using the shorthand a" do
      assert Wand.CLI.ArgParser.parse(["a", "poison"]) ==
               {:add, [%Wand.CLI.Commands.Add.Package{name: "poison"}]}
    end

    test "a package with a specific version" do
      assert Wand.CLI.ArgParser.parse(["add", "poison@3.1"]) ==
               {:add, [%Wand.CLI.Commands.Add.Package{name: "poison", version: "3.1"}]}
    end

    test "a package only for the test environment" do
      assert Wand.CLI.ArgParser.parse(["add", "poison", "--test"]) ==
               {:add, [%Wand.CLI.Commands.Add.Package{name: "poison", environments: [:test]}]}
    end

    test "a package for dev and test" do
      assert Wand.CLI.ArgParser.parse(["add", "poison", "--test", "--dev"]) ==
               {:add, [%Wand.CLI.Commands.Add.Package{name: "poison", environments: [:test, :dev]}]}
    end

    test "a package for a custom env" do
      assert Wand.CLI.ArgParser.parse(["add", "ex_doc", "--env=docs"]) ==
               {:add, [%Wand.CLI.Commands.Add.Package{name: "ex_doc", environments: [:docs]}]}
    end

    test "add multiple custom environments and prod" do
      command = OptionParser.split("add ex_doc --env=dogs --env=cat --prod")
      assert Wand.CLI.ArgParser.parse(command) ==
               {:add, [%Wand.CLI.Commands.Add.Package{name: "ex_doc", environments: [:prod, :dogs, :cat]}]}
    end

    test "set the runtime flag to false" do
      assert Wand.CLI.ArgParser.parse(["add", "poison", "--runtime=false"]) ==
               {:add, [%Wand.CLI.Commands.Add.Package{name: "poison", runtime: false}]}
    end
  end
end
