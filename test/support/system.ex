defmodule Wand.Test.Helpers.System do
  import Mox

  def stub_update_deps() do
    message = "Resolving Hex dependencies"
    expect(Wand.SystemMock, :cmd, fn "mix", ["deps.get"], _opts -> {message, 0} end)
  end

  def stub_failed_update_deps() do
    message = "Could not find a Mix.Project, please ensure you are running Mix in a directory with a mix.exs file"
    expect(Wand.SystemMock, :cmd, fn "mix", ["deps.get"], _opts -> {message, 1} end)
  end

  def stub_compile() do
    message = "===> Compiling parse_trans"
    expect(Wand.SystemMock, :cmd, fn "mix", ["compile"], _opts -> {message, 0} end)
  end

  def stub_failed_compile() do
    message = "** (SyntaxError) mix.exs:9"
    expect(Wand.SystemMock, :cmd, fn "mix", ["compile"], _opts -> {message, 1} end)
  end
end
