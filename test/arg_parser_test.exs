defmodule ArgParserTest do
  use ExUnit.Case, async: true
  alias Wand.CLI.ArgParser

  describe "help" do
    test "an unrecognized command is given" do
      assert ArgParser.parse(["wrong_command"]) == {:help, {:unrecognized, "wrong_command"}}
    end
  end
end
