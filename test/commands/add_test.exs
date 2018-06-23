defmodule AddTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.CLI.Commands.Add
  alias Wand.CLI.Commands.Add.{Git, Hex, Package, Path}

  describe "validate" do
    test "returns help if no args are given" do
      assert Add.validate(["add"]) == {:error, :missing_package}
    end

    test "returns help if invalid flags are given" do
      assert Add.validate(["add", "poison", "--wrong-flag"]) ==
               {:error, {:invalid_flag, "--wrong-flag"}}
    end

    test "returns help if single-package flags are used to install multiple packages" do
      command = OptionParser.split("add poison ex_doc --sparse=foo")
      assert Add.validate(command) == {:error, {:invalid_flag, "--sparse"}}
    end

    test "returns help if a flag for the wrong file type is given" do
      command = OptionParser.split("add ex_doc@file:/test --hex-name=foo")
      assert Add.validate(command) == {:error, {:invalid_flag, "--hex-name"}}
    end

    test "a simple package" do
      assert Add.validate(["add", "poison"]) == {:ok, [%Package{name: "poison"}]}
    end

    test "skip compiling" do
      assert Add.validate(["add", "poison", "--compile=false"]) ==
               {:ok, [%Package{name: "poison", compile: false}]}
    end

    test "skip downloading" do
      assert Add.validate(["add", "poison", "--download=false"]) ==
               {:ok, [%Package{name: "poison", download: false, compile: false}]}
    end

    test "with an organization and a repo" do
      expected = {
        :ok,
        [
          %Package{
            name: "poison",
            details: %Hex{
              organization: "mycompany",
              repo: "nothexpm"
            }
          }
        ]
      }

      assert Add.validate(["add", "poison", "--repo=nothexpm", "--organization=mycompany"]) ==
               expected
    end

    test "a package with a specific version" do
      assert Add.validate(["add", "poison@3.1"]) ==
               {:ok, [%Package{name: "poison", details: %Hex{version: "3.1"}}]}
    end

    test "a package only for the test environment" do
      assert Add.validate(["add", "poison", "--test"]) ==
               {:ok, [%Package{name: "poison", environments: [:test]}]}
    end

    test "a package for dev and test" do
      assert Add.validate(["add", "poison", "--test", "--dev"]) ==
               {:ok, [%Package{name: "poison", environments: [:test, :dev]}]}
    end

    test "a package for a custom env" do
      assert Add.validate(["add", "ex_doc", "--env=docs"]) ==
               {:ok, [%Package{name: "ex_doc", environments: [:docs]}]}
    end

    test "add multiple custom environments and prod" do
      command = OptionParser.split("add ex_doc --env=dogs --env=cat --prod")

      assert Add.validate(command) ==
               {:ok, [%Package{name: "ex_doc", environments: [:prod, :dogs, :cat]}]}
    end

    test "set the runtime flag to false" do
      assert Add.validate(["add", "poison", "--runtime=false"]) ==
               {:ok, [%Package{name: "poison", runtime: false}]}
    end

    test "set the override flag to true" do
      assert Add.validate(["add", "poison", "--override"]) ==
               {:ok, [%Package{name: "poison", override: true}]}
    end

    test "set the optional flag to true" do
      assert Add.validate(["add", "poison", "--optional"]) ==
               {:ok, [%Package{name: "poison", optional: true}]}
    end

    test "a local package" do
      expected =
        {:ok,
         [
           %Package{
             name: "test",
             details: %Path{
               path: "../test"
             }
           }
         ]}

      assert Add.validate(["add", "test@file:../test"]) == expected
    end

    test "an exact match" do
      assert Add.validate(["add", "ex_doc", "--exact"]) ==
               {:ok, [%Package{name: "ex_doc", mode: :exact}]}
    end

    test "Install the closest minor version" do
      assert Add.validate(["add", "ex_doc", "--around"]) ==
               {:ok, [%Package{name: "ex_doc", mode: :around}]}
    end

    test "a local umbrella package" do
      expected =
        {:ok,
         [
           %Package{
             name: "test",
             details: %Path{
               path: "../test",
               in_umbrella: true
             }
           }
         ]}

      assert Add.validate(["add", "test@file:../test", "--in-umbrella"]) == expected
    end

    test "Set the compile environment and disable-reading the app file" do
      expected = {
        :ok,
        [
          %Package{
            name: "poison",
            compile_env: "prod",
            read_app_file: false
          }
        ]
      }

      assert Add.validate(["add", "poison", "--compile-env=prod", "--read-app-file=false"]) ==
               expected
    end

    test "a http github package" do
      expected =
        {:ok,
         [
           %Package{
             name: "poison",
             details: %Git{
               uri: "https://github.com/devinus/poison.git"
             }
           }
         ]}

      assert Add.validate(["add", "poison@https://github.com/devinus/poison.git"]) == expected
    end

    test "a ssh github package" do
      expected =
        {:ok,
         [
           %Package{
             name: "poison",
             details: %Git{
               uri: "git@github.com:devinus/poison"
             }
           }
         ]}

      assert Add.validate(["add", "poison@git@github.com:devinus/poison"]) == expected
    end

    test "a ssh github package with a ref" do
      expected =
        {:ok,
         [
           %Package{
             name: "poison",
             details: %Git{
               uri: "git@github.com:devinus/poison",
               ref: "123"
             }
           }
         ]}

      assert Add.validate(["add", "poison@git@github.com:devinus/poison#123"]) == expected
    end

    test "a ssh github package with a branch" do
      expected =
        {:ok,
         [
           %Package{
             name: "poison",
             details: %Git{
               uri: "git@github.com:devinus/poison",
               branch: "master"
             }
           }
         ]}

      assert Add.validate(["add", "poison@git@github.com:devinus/poison#master", "--branch"]) ==
               expected
    end

    test "ssh github package with a tag, sparse, and submodules" do
      expected =
        {:ok,
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

      command =
        OptionParser.split(
          "add poison@git@github.com:devinus/poison#123 --tag --sparse=my_folder --submodules"
        )

      assert Add.validate(command) == expected
    end
  end

  describe "help" do
    setup :verify_on_exit!
    setup :stub_io
    test "banner" do
      Add.help(:banner)
    end
    def stub_io(_) do
      expect(Wand.CLI.IOMock, :puts, fn _message -> :ok end)
      :ok
    end
  end
end
