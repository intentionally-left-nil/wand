defmodule Wand.CLI.ArgParserTest do
  use ExUnit.Case
  describe "help" do
    test "when no args are given" do
      assert Wand.CLI.ArgParser.parse([]) == {:help, nil}
    end
  end
end
