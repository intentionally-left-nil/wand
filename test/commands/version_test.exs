defmodule VersionTest do
  use ExUnit.Case, async: true
  alias Wand.CLI.Commands.Version

  describe "validate" do
    test "wand --version returns the version" do
      assert Version.validate(["--version"]) == {:ok, []}
    end

    test "wand version returns the version" do
      assert Version.validate(["version"]) == {:ok, []}
    end
  end
end
