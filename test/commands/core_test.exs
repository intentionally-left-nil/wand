defmodule CoreTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.CLI.Commands.Core

  describe "validate" do
    test "returns help if nothing is passed in" do
      assert Core.validate(["core"]) == {:error, :wrong_command}
    end
    test "returns help if invalid commands are given" do
      assert Core.validate(["core", "wrong"]) == {:error, :wrong_command}
    end

    test "install" do
      assert Core.validate(["core", "install"]) == {:ok, {:install, []}}
    end

    test "install --force" do
      assert Core.validate(["core", "install", "--force"]) == {:ok, {:install, [force: true]}}
    end

    test "uninstall" do
      assert Core.validate(["core", "uninstall"]) == {:ok, :uninstall}
    end

    test "--version" do
      assert Core.validate(["core", "--version"]) == {:ok, :version}
    end

    test "version" do
      assert Core.validate(["core", "version"]) == {:ok, :version}
    end
  end

  describe "help" do
    setup :verify_on_exit!
    setup :stub_io

    test "wrong_command" do
      Core.help(:wrong_command)
    end

    test "banner" do
      Core.help(:banner)
    end

    test "verbose" do
      Core.help(:verbose)
    end

    def stub_io(_) do
      expect(Wand.IOMock, :puts, fn _message -> :ok end)
      :ok
    end
  end
end
