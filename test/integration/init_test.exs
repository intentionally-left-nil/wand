defmodule Wand.Integration.InitTest do
  use Wand.Test.IntegrationCase
  alias WandCore.WandFile

  test "wand init" do
    in_dir(fn ->
      IntegrationRunner.create_project()
      assert wand("init") == :ok
      assert WandFile.load() == {:ok, %WandFile{}}
    end)
  end
end
