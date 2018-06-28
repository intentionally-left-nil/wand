defmodule ModeTest do
  use ExUnit.Case, async: true

  describe "caret" do
    test "allows no updates for 0.0.1" do
      assert Wand.Mode.get_requirement(:caret, "0.0.1") == "== 0.0.1"
    end

    test "allows no updates for 0.0.7-dev" do
      assert Wand.Mode.get_requirement(:caret, "0.0.7-dev") == "== 0.0.7-dev"
    end

    test "allows ~> updates for 0.1.2" do
      assert Wand.Mode.get_requirement(:caret, "0.1.2") == "~> 0.1.2"
    end

    test "allows all minor updates for 3.4.5" do
      assert Wand.Mode.get_requirement(:caret, "3.4.5") == ">= 3.4.5 and < 4.0.0"
    end

    test "Parses 0.1 as 0.1.0" do
      assert Wand.Mode.get_requirement(:caret, "0.1") == "~> 0.1.0"
    end

    test "Parses 0.1-dev as 0.1.0-dev" do
      assert Wand.Mode.get_requirement(:caret, "0.1-dev") == "~> 0.1.0-dev"
    end

    test "Parses 3.1 as 3.1.0" do
      assert Wand.Mode.get_requirement(:caret, "3.1") == ">= 3.1.0 and < 4.0.0"
    end

    test "latest" do
      assert Wand.Mode.get_requirement(:caret, :latest) == {:latest, :caret}
    end
  end

  describe "exact" do
    test "0.0.1" do
      assert Wand.Mode.get_requirement(:exact, "0.0.1") == "== 0.0.1"
    end

    test "0.1.2-dev" do
      assert Wand.Mode.get_requirement(:exact, "0.1.2-dev") == "== 0.1.2-dev"
    end

    test "3.1.2+build1" do
      assert Wand.Mode.get_requirement(:exact, "3.1.2+build1") == "== 3.1.2+build1"
    end

    test "latest" do
      assert Wand.Mode.get_requirement(:exact, :latest) == {:latest, :exact}
    end
  end

  describe "tilde" do
    test "0.0.1" do
      assert Wand.Mode.get_requirement(:tilde, "0.0.1") == "~> 0.0.1"
    end

    test "0.1.2-dev" do
      assert Wand.Mode.get_requirement(:tilde, "0.1.2-dev") == "~> 0.1.2-dev"
    end

    test "3.1.2+build1" do
      assert Wand.Mode.get_requirement(:tilde, "3.1.2+build1") == "~> 3.1.2+build1"
    end

    test "latest" do
      assert Wand.Mode.get_requirement(:tilde, :latest) == {:latest, :tilde}
    end
  end
end
