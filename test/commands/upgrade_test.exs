defmodule UpgradeTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.CLI.Commands.Upgrade
  alias Wand.CLI.Commands.Upgrade.Options

  describe "validate" do
    test "returns help if invalid flags are given" do
      assert Upgrade.validate(["upgrade", "poison", "--wrong-flag"]) ==
               {:error, {:invalid_flag, "--wrong-flag"}}
    end

    test "a single package" do
      assert Upgrade.validate(["upgrade", "poison"]) ==
               {:ok, {["poison"], %Options{level: :major}}}
    end

    test "Upgrade to the latest version" do
      assert Upgrade.validate(["upgrade", "poison", "--latest"]) ==
               {:ok, {["poison"], %Options{level: :latest}}}
    end

    test "a single package to the next minor version" do
      assert Upgrade.validate(["upgrade", "poison", "--minor"]) ==
               {:ok, {["poison"], %Options{level: :minor}}}
    end

    test "If both major and minor are passed in, prefer major" do
      assert Upgrade.validate(["upgrade", "poison", "--minor", "--major"]) ==
               {:ok, {["poison"], %Options{level: :major}}}
    end

    test "upgrade multiple packages" do
      assert Upgrade.validate(["upgrade", "poison", "ex_doc", "--minor"]) ==
               {:ok, {["poison", "ex_doc"], %Options{level: :minor}}}
    end

    test "upgrade all packages if none passed in" do
      assert Upgrade.validate(["upgrade", "--minor"]) == {:ok, {:all, %Options{level: :minor}}}
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
end
