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
      assert Upgrade.validate(["upgrade", "poison"]) == {:ok, {["poison"], %Options{level: :major}}}
    end

    test "--latest is the same as major" do
      assert Upgrade.validate(["upgrade", "poison", "--patch", "--latest"]) ==
               {:ok, {["poison"], %Options{level: :major}}}
    end

    test "a single package to the next minor version" do
      assert Upgrade.validate(["upgrade", "poison", "--minor"]) == {:ok, {["poison"], %Options{level: :minor}}}
    end

    test "a single package to the next patch version" do
      assert Upgrade.validate(["upgrade", "poison", "--patch"]) == {:ok, {["poison"], %Options{level: :patch}}}
    end

    test "If both major and minor are passed in, prefer major" do
      assert Upgrade.validate(["upgrade", "poison", "--minor", "--major"]) ==
               {:ok, {["poison"], %Options{level: :major}}}
    end

    test "upgrade multiple packages" do
      assert Upgrade.validate(["upgrade", "poison", "ex_doc", "--patch"]) ==
               {:ok, {["poison", "ex_doc"], %Options{level: :patch}}}
    end

    test "upgrade all packages if none passed in" do
      assert Upgrade.validate(["upgrade", "--patch"]) == {:ok, {:all, %Options{level: :patch}}}
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
end
