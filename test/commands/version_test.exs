defmodule CLI.VersionTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.CLI.Commands.Version

  describe "validate" do
    test "wand --version returns the version" do
      assert Version.validate(["--version"]) == {:ok, []}
    end

    test "wand version returns the version" do
      assert Version.validate(["version"]) == {:ok, []}
    end
  end

  describe "help" do
    setup :verify_on_exit!
    setup :stub_io

    test "banner" do
      Version.help(:banner)
    end

    test "verbose" do
      Version.help(:verbose)
    end

    def stub_io(_) do
      expect(Wand.IOMock, :puts, fn _message -> :ok end)
      :ok
    end
  end
end
