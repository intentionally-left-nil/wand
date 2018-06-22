defmodule OutdatedTest do
  use ExUnit.Case, async: true
  alias Wand.CLI.Commands.Outdated

  describe "validate" do
    test "returns help when arguments are given" do
      assert Outdated.validate(["outdated", "poison"]) == {:error, :wrong_command}
    end
  end
end
