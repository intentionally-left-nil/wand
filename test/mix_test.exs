defmodule MixTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.Test.Helpers

  setup :verify_on_exit!

  test "update_deps" do
    Helpers.System.stub_update_deps()
    assert Wand.CLI.Mix.update_deps() == :ok
  end

  test "update_deps fails" do
    Helpers.System.stub_failed_update_deps()

    assert Wand.CLI.Mix.update_deps() ==
             {:error,
              {1,
               "Could not find a Mix.Project, please ensure you are running Mix in a directory with a mix.exs file"}}
  end

  test "compile dependencies" do
    Helpers.System.stub_compile()
    assert Wand.CLI.Mix.compile() == :ok
  end

  test "compile fails" do
    Helpers.System.stub_failed_compile()
    assert Wand.CLI.Mix.compile() == {:error, {1, "** (SyntaxError) mix.exs:9"}}
  end

  test "cleanup_deps" do
    Helpers.System.stub_cleanup_deps()
    assert Wand.CLI.Mix.cleanup_deps() == :ok
  end

  test "cleanup_deps fails" do
    Helpers.System.stub_failed_cleanup_deps()
    assert Wand.CLI.Mix.cleanup_deps() == {:error, {1, "** (CompileError) mix.lock:2"}}
  end

  test "get_deps" do
    Helpers.System.stub_get_deps()

    assert Wand.CLI.Mix.get_deps(".") ==
             {:ok,
              [
                ["earmark", "~> 1.2"],
                ["mox", "~> 0.3.2", [["only", ":test"]]],
                ["ex_doc", ">= 0.0.0", [["only", ":dev"]]]
              ]}
  end

  test "get_deps fails" do
    Helpers.System.stub_failed_get_deps()
    assert Wand.CLI.Mix.get_deps(".") == {:error, {1, ""}}
  end
end
