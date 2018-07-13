defmodule Wand.Integration.InitTest do
  use Wand.Test.IntegrationCase
  alias WandCore.WandFile

  test "Initialize, and modify the wand file" do
    in_dir(fn ->
      execute("mix new .")
      assert wand("init") == :ok
      assert WandFile.load() == {:ok, %WandFile{}}
    end)
  end
end
