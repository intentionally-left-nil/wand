defmodule InitTest do
  use ExUnit.Case, async: true
  alias Wand.CLI.Commands.Init

  describe "validate" do
    test "returns help if invalid flags are given" do
      assert Init.validate(["init", "--wrong-flag"]) ==
               {:error, {:invalid_flag, "--wrong-flag"}}
    end

    test "initializes the current path if no args are given" do
      assert Init.validate(["init"]) == {:ok, {"./", []}}
    end

    test "uses a custom path" do
      assert Init.validate(["init", "../foo"]) == {:ok, {"../foo", []}}
    end

    test "passes in overwrite" do
      assert Init.validate(["init", "--overwrite"]) == {:ok, {"./", [overwrite: true]}}
    end

    test "passes in task_only and force" do
      assert Init.validate(["init", "--overwrite", "--task-only"]) ==
               {:ok, {"./", [overwrite: true, task_only: true]}}
    end
  end
end
