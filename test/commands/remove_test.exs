defmodule RemoveTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.CLI.Executor.Result
  alias Wand.CLI.Commands.Remove
  alias Wand.Test.Helpers
  alias WandCore.WandFile

  describe "validate" do
    test "returns help if no args are given" do
      assert Remove.validate(["remove"]) == {:error, :missing_package}
    end

    test "returns an array of one package to remove" do
      assert Remove.validate(["remove", "poison"]) == {:ok, ["poison"]}
    end

    test "returns an array of multiple packages to remove" do
      assert Remove.validate(["remove", "poison", "ex_doc"]) == {:ok, ["poison", "ex_doc"]}
    end
  end

  describe "help" do
    setup :verify_on_exit!
    setup :stub_io

    test "missing_package" do
      Remove.help(:missing_package)
    end

    test "banner" do
      Remove.help(:banner)
    end

    test "verbose" do
      Remove.help(:verbose)
    end

    def stub_io(_) do
      expect(Wand.IOMock, :puts, fn _message -> :ok end)
      :ok
    end
  end

  describe "execute" do
    test "Does nothing if the dependency is not being used" do
      file = %WandFile{}
      assert Remove.execute(["poison"], %{wand_file: file}) == {:ok, %Result{wand_file: file}}
    end

    test "removes the dependency" do
      file = %WandFile{
        dependencies: [
          Helpers.WandFile.poison(),
          Helpers.WandFile.mox()
        ]
      }

      expected_file = %WandFile{
        dependencies: [
          Helpers.WandFile.mox()
        ]
      }
      assert Remove.execute(["poison"], %{wand_file: file}) == {:ok, %Result{wand_file: expected_file}}
    end

    test "removes multiple dependencies" do
      file = %WandFile{
        dependencies: [
          Helpers.WandFile.poison(),
          Helpers.WandFile.mox()
        ]
      }

      assert Remove.execute(["mox", "poison", "not_present"], %{wand_file: file}) == {:ok, %Result{wand_file: %WandFile{}}}
    end
  end

  describe "after_save" do
    test "successfully cleans up dependencies" do
      Helpers.System.stub_cleanup_deps()
      assert Remove.after_save(["poison"]) == :ok
    end

    test ":install_deps_error if cleaning the deps fails" do
      Helpers.System.stub_failed_cleanup_deps()
      assert Remove.after_save(["poison"]) == {:error, :install_deps_error, :nil}
    end
  end
end
