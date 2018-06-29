defmodule Wand.Test.Helpers.System do
  import Mox

  def stub_update_deps() do
    message = "Resolving Hex dependencies"
    expect(Wand.SystemMock, :cmd, fn "mix", ["deps.get"], _opts -> {message, 0} end)
  end

  def stub_failed_update_deps() do
    message =
      "Could not find a Mix.Project, please ensure you are running Mix in a directory with a mix.exs file"

    expect(Wand.SystemMock, :cmd, fn "mix", ["deps.get"], _opts -> {message, 1} end)
  end

  def stub_compile() do
    message = "===> Compiling parse_trans"
    expect(Wand.SystemMock, :cmd, fn "mix", ["deps.compile"], _opts -> {message, 0} end)
  end

  def stub_failed_compile() do
    message = "** (SyntaxError) mix.exs:9"
    expect(Wand.SystemMock, :cmd, fn "mix", ["deps.compile"], _opts -> {message, 1} end)
  end

  def stub_cleanup_deps() do
    expect(Wand.SystemMock, :cmd, fn "mix", ["deps.unlock", "--unused"], _opts -> {"", 0} end)
  end

  def stub_failed_cleanup_deps() do
    message = "** (CompileError) mix.lock:2"

    expect(Wand.SystemMock, :cmd, fn "mix", ["deps.unlock", "--unused"], _opts -> {message, 1} end)
  end

  def stub_get_deps() do
    [
      ["earmark", "~> 1.2"],
      ["mox", "~> 0.3.2", [["only", ":test"]]],
      ["ex_doc", ">= 0.0.0", [["only", ":dev"]]]
    ]
    |> stub_get_deps()
  end

  def stub_get_deps(deps) do
    message = WandCore.Poison.encode!(deps)

  expect(Wand.SystemMock, :cmd, fn "mix", ["wand_core.get_deps"], _opts -> {message, 0} end)
  end

  def stub_failed_get_deps() do
    expect(Wand.SystemMock, :cmd, fn "mix", ["wand_core.get_deps"], _opts -> {"", 1} end)
  end

  def stub_get_bad_deps() do
    message =
      [["mox", "~> 0.3.2", [["only", "test"]]], ["oops", "ex_doc", ">= 0.0.0", [["only", "dev"]]]]
      |> WandCore.Poison.encode!()

    expect(Wand.SystemMock, :cmd, fn "mix", ["wand_core.get_deps"], _opts -> {message, 0} end)
  end
end
