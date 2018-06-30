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
end
