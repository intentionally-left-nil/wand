defmodule OutdatedTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.CLI.Commands.Outdated

  describe "validate" do
    test "returns help when arguments are given" do
      assert Outdated.validate(["outdated", "poison"]) == {:error, :wrong_command}
    end
  end

  describe "help" do
    setup :verify_on_exit!
    setup :stub_io

    test "invalid flag" do
      Outdated.help({:invalid_flag, "--wrong-flag"})
    end

    test "wrong command" do
      Outdated.help(:wrong_command)
    end

    test "banner" do
      Outdated.help(:banner)
    end

    test "verbose" do
      Outdated.help(:verbose)
    end

    def stub_io(_) do
      expect(Wand.CLI.IOMock, :puts, fn _message -> :ok end)
      :ok
    end
  end
end
