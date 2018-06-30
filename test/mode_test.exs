defmodule ModeTest do
  use ExUnit.Case, async: true
  alias Wand.Mode

  describe "caret" do
    test "allows no updates for 0.0.1" do
      assert Mode.get_requirement(:caret, "0.0.1") == {:ok, ">= 0.0.1 and <= 0.0.1"}
    end

    test "allows no updates for 0.0.7-dev" do
      assert Mode.get_requirement(:caret, "0.0.7-dev") == {:ok, ">= 0.0.7-dev and <= 0.0.7-dev"}
    end

    test "allows ~> updates for 0.1.2" do
      assert Mode.get_requirement(:caret, "0.1.2") == {:ok, ">= 0.1.2 and < 0.2.0"}
    end

    test "allows all minor updates for 3.4.5" do
      assert Mode.get_requirement(:caret, "3.4.5") == {:ok, ">= 3.4.5 and < 4.0.0"}
    end

    test "Parses 0.1 as 0.1.0" do
      assert Mode.get_requirement(:caret, "0.1") == {:ok, ">= 0.1.0 and < 0.2.0"}
    end

    test "Parses 0.1-dev as 0.1.0-dev" do
      assert Mode.get_requirement(:caret, "0.1-dev") == {:ok, ">= 0.1.0-dev and < 0.2.0"}
    end

    test "Parses 3.1 as 3.1.0" do
      assert Mode.get_requirement(:caret, "3.1") == {:ok, ">= 3.1.0 and < 4.0.0"}
    end

    test "latest" do
      assert Mode.get_requirement(:caret, :latest) == {:ok, {:latest, :caret}}
    end
  end

  describe "exact" do
    test "0.0.1" do
      assert Mode.get_requirement(:exact, "0.0.1") == {:ok, "== 0.0.1"}
    end

    test "0.1.2-dev" do
      assert Mode.get_requirement(:exact, "0.1.2-dev") == {:ok, "== 0.1.2-dev"}
    end

    test "3.1.2+build1" do
      assert Mode.get_requirement(:exact, "3.1.2+build1") == {:ok, "== 3.1.2+build1"}
    end

    test "latest" do
      assert Mode.get_requirement(:exact, :latest) == {:ok, {:latest, :exact}}
    end
  end

  describe "tilde" do
    test "0.0.1" do
      assert Mode.get_requirement(:tilde, "0.0.1") == {:ok, "~> 0.0.1"}
    end

    test "0.1.2-dev" do
      assert Mode.get_requirement(:tilde, "0.1.2-dev") == {:ok, "~> 0.1.2-dev"}
    end

    test "3.1.2+build1" do
      assert Mode.get_requirement(:tilde, "3.1.2+build1") == {:ok, "~> 3.1.2+build1"}
    end

    test "latest" do
      assert Mode.get_requirement(:tilde, :latest) == {:ok, {:latest, :tilde}}
    end
  end

  describe "get_requirement!" do
    test "returns the requirement on success" do
      assert Mode.get_requirement!(:tilde, "0.0.1") == "~> 0.0.1"
    end

    test "raieses an exception on failure" do
      assert_raise(MatchError, fn ->
        Mode.get_requirement!(:tilde, "NOT_A_VERSION") == "~> 0.0.1"
      end)
    end
  end

  describe "from_requirement" do
    test "just numbers" do
      assert Mode.from_requirement("2.0.0") == :exact
    end

    test "exact" do
      assert Mode.from_requirement("==2.0.0") == :exact
    end

    test "exact patch" do
      assert Mode.from_requirement("== 0.0.1") == :exact
    end

    test "tilde" do
      assert Mode.from_requirement("~>2.0.0") == :tilde
    end

    test "tilde patch" do
      assert Mode.from_requirement("~> 0.0.3") == :tilde
    end

    test "caret patch" do
      assert Mode.from_requirement(">= 0.0.3 and <= 0.0.3") == :caret
    end

    test "caret with pre" do
      assert Mode.from_requirement(">= 0.0.3-dev and <= 0.0.3-dev") == :caret
    end

    test "caret with minor" do
      assert Mode.from_requirement(">= 0.1.0 and < 0.2.0") == :caret
    end

    test "caret with minor and pre" do
      assert Mode.from_requirement(">= 0.1.2-dev+22 and < 0.2.0") == :caret
    end

    test "caret with major" do
      assert Mode.from_requirement(">= 2.3.0 and < 3.0.0") == :caret
    end

    test "custom with tilde and a clause" do
      assert Mode.from_requirement("~> 0.1.0 and < 0.2.0") == :custom
    end

    test "custom with multiple ands" do
      assert Mode.from_requirement(">= 0.1.0 and < 0.2.0 and < 0.3.0") == :custom
    end

    test "custom with old >= new" do
      assert Mode.from_requirement(">= 3.0.4 and < 1.0.3") == :custom
    end

    test "custom with patches not equal" do
      assert Mode.from_requirement(">= 0.0.3 and < 0.0.4") == :custom
    end

    test "custom with minor more than 1 greater" do
      assert Mode.from_requirement(">= 0.1.0 and < 0.3.0") == :custom
    end

    test "custom with new version having a patch" do
      assert Mode.from_requirement(">= 0.1.3 and < 0.2.1") == :custom
    end

    test "custom with major more than 1 greater" do
      assert Mode.from_requirement(">= 2.3.0 and < 4.0.0") == :custom
    end

    test "custom with major new version having a patch" do
      assert Mode.from_requirement(">= 1.2.3 and < 2.0.1") == :custom
    end

    test "custom with major new version having a minor" do
      assert Mode.from_requirement(">= 1.2.3 and < 2.3.0") == :custom
    end
  end
end
