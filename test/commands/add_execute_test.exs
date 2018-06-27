defmodule AddExecuteTest do
  use ExUnit.Case
  import Mox
  alias Wand.CLI.Commands.Add
  alias Wand.CLI.Commands.Add.Package
  alias Wand.Test.Helpers
  alias Wand.WandFile
  alias Wand.WandFile.Dependency

  describe "execute" do
    setup :verify_on_exit!
    setup :set_mox_global

    test "adds a single package" do
      Helpers.Hex.stub_poison()
      Helpers.WandFile.stub_empty()
      %WandFile{
        dependencies: [%Dependency{name: "poison", requirement: "~> 3.1.0"}]
      }
      |> Helpers.WandFile.stub_save()
      assert Add.execute([%Package{name: "poison"}]) == :ok
    end
  end
end
