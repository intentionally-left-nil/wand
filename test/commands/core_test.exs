defmodule CoreTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.CLI.Commands.Core
  alias Wand.Test.Helpers
  import Wand.CLI.Errors, only: [error: 1]

  describe "validate" do
    test "returns help if nothing is passed in" do
      assert Core.validate(["core"]) == {:error, :wrong_command}
    end

    test "returns help if invalid commands are given" do
      assert Core.validate(["core", "wrong"]) == {:error, :wrong_command}
    end

    test "returns help if an invalid flag is given" do
      assert Core.validate(["core", "install", "--version"]) == {:error, {:invalid_flag, "--version"}}
    end

    test "install" do
      assert Core.validate(["core", "install"]) == {:ok, :install}
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

  describe "execute version" do
    setup :verify_on_exit!
    test "succesfully gets the version" do
      version = "3.2.1"
      Helpers.System.stub_core_version(version)
      expect(Wand.IOMock, :puts, fn ^version -> :ok end)
      Sys
      assert Core.execute(:version) == :ok
    end

    test "fails to get the version" do
      Helpers.System.stub_core_version_missing()
      Helpers.IO.stub_stderr()
      assert Core.execute(:version) == error(:wand_core_missing)
    end
  end

  describe "execute install" do
    test "successfully installs the core" do
      Helpers.System.stub_install_core()
      assert Core.execute(:install) == :ok
    end

    test "Returns an error if installing the core fails" do
      Helpers.System.stub_failed_install_core()
      Helpers.IO.stub_stderr()
      assert Core.execute(:install) == {:error, 1}
    end
  end
end
