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

  describe "add" do
    test "returns help if no args are given" do
      assert ArgParser.parse(["add"]) == {:help, :add, :missing_package}
    end

    test "returns help if invalid flags are given" do
      assert ArgParser.parse(["add", "poison", "--wrong-flag"]) ==
               {:help, :add, {:invalid_flag, "--wrong-flag"}}
    end

    test "returns help if single-package flags are used to install multiple packages" do
      command = OptionParser.split("add poison ex_doc --sparse=foo")
      assert ArgParser.parse(command) == {:help, :add, {:invalid_flag, "--sparse"}}
    end

    test "returns help if a flag for the wrong file type is given" do
      command = OptionParser.split("add ex_doc@file:/test --hex-name=foo")
      assert ArgParser.parse(command) == {:help, :add, {:invalid_flag, "--hex-name"}}
    end

    test "a simple package" do
      assert ArgParser.parse(["add", "poison"]) == {:add, [%Package{name: "poison"}]}
    end

    test "skip compiling" do
      assert ArgParser.parse(["add", "poison", "--compile=false"]) == {:add, [%Package{name: "poison", compile: false}]}
    end

    test "skip downloading" do
      assert ArgParser.parse(["add", "poison", "--download=false"]) == {:add, [%Package{name: "poison", download: false, compile: false}]}
    end

    test "using the shorthand a" do
      assert ArgParser.parse(["a", "poison"]) == {:add, [%Package{name: "poison"}]}
    end

    test "with an organization and a repo" do
      expected = {
        :add,
        [
          %Package{
            name: "poison",
            details: %Hex{
              organization: "mycompany",
              repo: "nothexpm",
            }
          }
        ]
      }
      assert ArgParser.parse(["add", "poison", "--repo=nothexpm", "--organization=mycompany"]) == expected
    end

    test "a package with a specific version" do
      assert ArgParser.parse(["add", "poison@3.1"]) ==
               {:add, [%Package{name: "poison", details: %Hex{version: "3.1"}}]}
    end

    test "a package only for the test environment" do
      assert ArgParser.parse(["add", "poison", "--test"]) ==
               {:add, [%Package{name: "poison", environments: [:test]}]}
    end

    test "a package for dev and test" do
      assert ArgParser.parse(["add", "poison", "--test", "--dev"]) ==
               {:add, [%Package{name: "poison", environments: [:test, :dev]}]}
    end

    test "a package for a custom env" do
      assert ArgParser.parse(["add", "ex_doc", "--env=docs"]) ==
               {:add, [%Package{name: "ex_doc", environments: [:docs]}]}
    end

    test "add multiple custom environments and prod" do
      command = OptionParser.split("add ex_doc --env=dogs --env=cat --prod")

      assert ArgParser.parse(command) ==
               {:add, [%Package{name: "ex_doc", environments: [:prod, :dogs, :cat]}]}
    end

    test "set the runtime flag to false" do
      assert ArgParser.parse(["add", "poison", "--runtime=false"]) ==
               {:add, [%Package{name: "poison", runtime: false}]}
    end

    test "set the override flag to true" do
      assert ArgParser.parse(["add", "poison", "--override"]) ==
               {:add, [%Package{name: "poison", override: true}]}
    end

    test "set the optional flag to true" do
      assert ArgParser.parse(["add", "poison", "--optional"]) ==
               {:add, [%Package{name: "poison", optional: true}]}
    end

    test "a local package" do
      expected =
        {:add,
         [
           %Package{
             name: "test",
             details: %Path{
               path: "../test"
             }
           }
         ]}

      assert ArgParser.parse(["add", "test@file:../test"]) == expected
    end

    test "an exact match" do
      assert ArgParser.parse(["add", "ex_doc", "--exact"]) ==
               {:add, [%Package{name: "ex_doc", mode: :exact}]}
    end

    test "Install the closest minor version" do
      assert ArgParser.parse(["add", "ex_doc", "--around"]) ==
               {:add, [%Package{name: "ex_doc", mode: :around}]}
    end

    test "a local umbrella package" do
      expected =
        {:add,
         [
           %Package{
             name: "test",
             details: %Path{
               path: "../test",
               umbrella: true,
             }
           }
         ]}
      assert ArgParser.parse(["add", "test@file:../test", "--umbrella"]) == expected
    end

    test "Set the compile environment and disable-reading the app file" do
      expected = {
        :add,
        [
          %Package{
            name: "poison",
            compile_env: "prod",
            read_app_file: false,
          }
        ]
      }
      assert ArgParser.parse(["add", "poison", "--compile-env=prod", "--read-app-file=false"]) == expected
    end

    test "a http github package" do
      expected =
        {:add,
         [
           %Package{
             name: "poison",
             details: %Git{
               uri: "https://github.com/devinus/poison.git"
             }
           }
         ]}
      assert ArgParser.parse(["add", "poison@https://github.com/devinus/poison.git"]) == expected
    end

    test "a ssh github package" do
      expected =
        {:add,
         [
           %Package{
             name: "poison",
             details: %Git{
               uri: "git@github.com:devinus/poison"
             }
           }
         ]}
      assert ArgParser.parse(["add", "poison@git@github.com:devinus/poison"]) == expected
    end

    test "a ssh github package with a ref" do
      expected =
        {:add,
         [
           %Package{
             name: "poison",
             details: %Git{
               uri: "git@github.com:devinus/poison",
               ref: "123"
             }
           }
         ]}
      assert ArgParser.parse(["add", "poison@git@github.com:devinus/poison#123"]) == expected
    end

    test "a ssh github package with a branch" do
      expected =
        {:add,
         [
           %Package{
             name: "poison",
             details: %Git{
               uri: "git@github.com:devinus/poison",
               branch: "master"
             }
           }
         ]}
      assert ArgParser.parse(["add", "poison@git@github.com:devinus/poison#master", "--branch"]) == expected
    end

    test "ssh github package with a tag, sparse, and submodules" do
      expected =
        {:add,
         [
           %Package{
             name: "poison",
             details: %Git{
               uri: "git@github.com:devinus/poison",
               tag: "123",
               sparse: "my_folder",
               submodules: true
             }
           }
         ]}
      command = OptionParser.split("add poison@git@github.com:devinus/poison#123 --tag --sparse=my_folder --submodules")
      assert ArgParser.parse(command) == expected
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
      assert ArgParser.parse(["upgrade", "poison"]) ==
               {:upgrade, {["poison"], :major}}
    end

    test "a single package with the shorthand" do
      assert ArgParser.parse(["u", "poison"]) ==
               {:upgrade, {["poison"], :major}}
    end

    test "--latest is the same as major" do
      assert ArgParser.parse(["upgrade", "poison", "--patch", "--latest"]) ==
               {:upgrade, {["poison"], :major}}
    end

    test "a single package to the next minor version" do
      assert ArgParser.parse(["upgrade", "poison", "--minor"]) ==
               {:upgrade, {["poison"], :minor}}
    end

    test "a single package to the next patch version" do
      assert ArgParser.parse(["upgrade", "poison", "--patch"]) ==
               {:upgrade, {["poison"], :patch}}
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
      assert ArgParser.parse(["upgrade", "--patch"]) ==
               {:upgrade, {:all, :patch}}

    end
  end

  describe "outdated" do
    test "returns help when arguments are given" do
      assert ArgParser.parse(["outdated", "poison"]) ==
               {:help, :outdated, :wrong_command}
    end
  end

  describe "init" do
    test "returns help if invalid flags are given" do
      assert ArgParser.parse(["init", "--wrong-flag"]) ==
               {:help, :init, {:invalid_flag, "--wrong-flag"}}
    end

    test "initializes the current path if no args are given" do
      assert ArgParser.parse(["init"]) ==
               {:init, {"./", []}}
    end

    test "uses a custom path" do
      assert ArgParser.parse(["init", "../foo"]) ==
               {:init, {"../foo", []}}
    end

    test "passes in overwrite" do
      assert ArgParser.parse(["init", "--overwrite"]) ==
               {:init, {"./", [overwrite: true]}}
    end

    test "passes in task_only and force" do
      assert ArgParser.parse(["init", "--overwrite", "--task-only"]) ==
               {:init, {"./", [overwrite: true, task_only: true]}}
    end
  end
end
