defmodule Wand.Integration.InitTest do
  use Wand.Test.IntegrationCase
  alias WandCore.WandFile
  alias WandCore.WandFile.Dependency

  test "Initialize, and modify the wand file" do
    in_dir(fn ->
      execute("mix new .")
      assert wand("init") == :ok
      assert WandFile.load() == {:ok, %WandFile{}}
      assert wand("add modglobal") == :ok
      assert WandFile.load() == {:ok, %WandFile{dependencies: [modglobal()]}}
    end)
  end

  defp modglobal() do
    %Dependency{name: "modglobal", opts: %{}, requirement: ">= 0.2.3 and < 0.3.0"}
  end
end
