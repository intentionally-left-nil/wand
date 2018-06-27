defmodule AddExecuteTest do
  use ExUnit.Case
  import Mox
  import Wand.CLI.Errors, only: [error: 1]
  alias Wand.CLI.Commands.Add
  alias Wand.CLI.Commands.Add.Package
  alias Wand.Test.Helpers
  alias Wand.WandFile
  alias Wand.WandFile.Dependency

  setup :verify_on_exit!
  setup :set_mox_global

  test "errors when the file cannot be loaded" do
    Helpers.WandFile.stub_no_file()
    assert Add.execute([%Package{name: "poison"}]) == error(:missing_wand_file)
  end

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
