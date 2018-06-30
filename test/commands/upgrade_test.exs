defmodule UpgradeTest do
  use ExUnit.Case, async: true
  import Mox
  import Wand.CLI.Errors, only: [error: 1]
  alias Wand.Test.Helpers
  alias Wand.CLI.Commands.Upgrade
  alias Wand.CLI.Commands.Upgrade.Options
  alias WandCore.WandFile
  alias WandCore.WandFile.Dependency

  describe "validate" do
    test "returns help if invalid flags are given" do
      assert Upgrade.validate(["upgrade", "poison", "--wrong-flag"]) ==
               {:error, {:invalid_flag, "--wrong-flag"}}
    end

    test ":invalid_flag if --exact is given without --latest" do
      assert Upgrade.validate(["upgrade", "poison", "--exact"]) ==
               {:error, {:invalid_flag, "--exact"}}
    end

    test "a single package" do
      assert Upgrade.validate(["upgrade", "poison"]) ==
               {:ok, {["poison"], %Options{}}}
    end

    test "Upgrade to the latest version" do
      assert Upgrade.validate(["upgrade", "poison", "--latest"]) ==
               {:ok, {["poison"], %Options{latest: true}}}
    end

    test "Latest, using the exact version" do
      assert Upgrade.validate(["upgrade", "poison", "--exact", "--latest"]) ==
               {:ok, {["poison"], %Options{latest: true, mode: :exact}}}
    end


    test "If both tilde and exact are passed in, prefer exact" do
      assert Upgrade.validate(["upgrade", "poison", "--tilde", "--latest", "--exact"]) ==
               {:ok, {["poison"], %Options{latest: true, mode: :exact}}}
    end

    test "upgrade multiple packages" do
      assert Upgrade.validate(["upgrade", "poison", "ex_doc"]) ==
               {:ok, {["poison", "ex_doc"], %Options{}}}
    end

    test "upgrade all packages if none passed in" do
      assert Upgrade.validate(["upgrade"]) == {:ok, {:all, %Options{}}}
    end

    test "skip compiling" do
      assert Upgrade.validate(["upgrade", "poison", "--compile=false"]) ==
               {:ok, {["poison"], %Options{compile: false}}}
    end

    test "skip downloading" do
      assert Upgrade.validate(["upgrade", "poison", "--download=false"]) ==
               {:ok, {["poison"], %Options{download: false, compile: false}}}
    end
  end

  describe "help" do
    setup :verify_on_exit!
    setup :stub_io

    test "invalid_flag" do
      Upgrade.help({:invalid_flag, "--foobaz"})
    end

    test "banner" do
      Upgrade.help(:banner)
    end

    test "verbose" do
      Upgrade.help(:verbose)
    end

    def stub_io(_) do
      expect(Wand.IOMock, :puts, fn _message -> :ok end)
      :ok
    end
  end

  describe "execute" do
    test ":missing_wand_file if cannot open wand file" do
      Helpers.WandFile.stub_no_file()
      Helpers.IO.stub_stderr()
      assert Upgrade.execute({["poison"], %Options{}}) == error(:missing_wand_file)
    end

    test ":package_not_found if the package is not in wand.json" do
      Helpers.WandFile.stub_load()
      Helpers.IO.stub_stderr()
      assert Upgrade.execute({["poison"], %Options{}}) == error(:package_not_found)
    end

    test ":hex_api_error if getting the package from hex fails" do
      file = %WandFile{
        dependencies: [Helpers.WandFile.poison()]
      }
      Helpers.WandFile.stub_load(file)
      Helpers.IO.stub_stderr()
      Helpers.Hex.stub_not_found()

      assert Upgrade.execute({["poison"], %Options{}}) == error(:hex_api_error)

    end

    test "update all the dependencies" do
      Helpers.WandFile.stub_load()
      assert Upgrade.execute({:all, %Options{}}) == :ok
    end
  end
end
