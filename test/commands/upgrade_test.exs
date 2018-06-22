defmodule UpgradeTest do
  use ExUnit.Case, async: true
  alias Wand.CLI.Commands.Upgrade

  describe "validate" do
    test "returns help if invalid flags are given" do
      assert Upgrade.validate(["upgrade", "poison", "--wrong-flag"]) ==
               {:error, {:invalid_flag, "--wrong-flag"}}
    end

    test "a single package" do
      assert Upgrade.validate(["upgrade", "poison"]) == {:ok, {["poison"], :major}}
    end

    test "--latest is the same as major" do
      assert Upgrade.validate(["upgrade", "poison", "--patch", "--latest"]) ==
               {:ok, {["poison"], :major}}
    end

    test "a single package to the next minor version" do
      assert Upgrade.validate(["upgrade", "poison", "--minor"]) == {:ok, {["poison"], :minor}}
    end

    test "a single package to the next patch version" do
      assert Upgrade.validate(["upgrade", "poison", "--patch"]) == {:ok, {["poison"], :patch}}
    end

    test "If both major and minor are passed in, prefer major" do
      assert Upgrade.validate(["upgrade", "poison", "--minor", "--major"]) ==
               {:ok, {["poison"], :major}}
    end

    test "upgrade multiple packages" do
      assert Upgrade.validate(["upgrade", "poison", "ex_doc", "--patch"]) ==
               {:ok, {["poison", "ex_doc"], :patch}}
    end

    test "upgrade all packages if none passed in" do
      assert Upgrade.validate(["upgrade", "--patch"]) == {:ok, {:all, :patch}}
    end
  end
end
