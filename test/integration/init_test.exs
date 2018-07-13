defmodule Wand.Integration.InitTest do
  use Wand.Test.IntegrationCase
  alias WandCore.WandFile
  alias WandCore.WandFile.Dependency

  test "Initialize, and modify the wand file" do
    in_dir(fn ->
      assert execute("mix new .") == :ok
      assert wand("init") == :ok
      assert_wandfile()
      assert wand("add modglobal") == :ok
      assert_wandfile(%WandFile{dependencies: [modglobal()]})
      assert execute("mix deps.get") == :ok
      assert wand("remove modglobal") == :ok
      assert_wandfile()
    end)
  end

  test "Upgrade a dependency" do
    in_dir(fn ->
      assert execute("mix new .") == :ok
      assert wand("init") == :ok
      assert wand("add modglobal@0.1") == :ok
      assert_wandfile(%WandFile{dependencies: [modglobal(">= 0.1.0 and < 0.2.0")]})
      assert wand("upgrade modglobal") == :ok
      assert_wandfile(%WandFile{dependencies: [modglobal(">= 0.1.0 and < 0.2.0")]})

      # Now update so the version is changed
      assert wand("upgrade modglobal --latest --exact") == :ok
      assert_wandfile(%WandFile{dependencies: [modglobal("== 0.2.3")]})
    end)
  end

  defp modglobal(requirement \\ ">= 0.2.3 and < 0.3.0") do
    %Dependency{name: "modglobal", requirement: requirement}
  end

  defp assert_wandfile(file \\ %WandFile{}) do
      assert WandFile.load() == {:ok, file}
  end
end
