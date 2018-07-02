defmodule RemoveTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.CLI.Error
  alias Wand.CLI.Commands.Remove
  alias Wand.Test.Helpers
  alias WandCore.WandFile

  describe "validate" do
    test "returns help if no args are given" do
      assert Remove.validate(["remove"]) == {:error, :missing_package}
    end

    test "returns an array of one package to remove" do
      assert Remove.validate(["remove", "poison"]) == {:ok, ["poison"]}
    end

    test "returns an array of multiple packages to remove" do
      assert Remove.validate(["remove", "poison", "ex_doc"]) == {:ok, ["poison", "ex_doc"]}
    end
  end

  describe "help" do
    setup :verify_on_exit!
    setup :stub_io

    test "missing_package" do
      Remove.help(:missing_package)
    end

    test "banner" do
      Remove.help(:banner)
    end

    test "verbose" do
      Remove.help(:verbose)
    end

    def stub_io(_) do
      expect(Wand.IOMock, :puts, fn _message -> :ok end)
      :ok
    end
  end

  describe "execute errors" do
    test "Error saving the wand file" do
      file = %WandFile{}
      Helpers.WandFile.stub_cannot_save(file)
      Helpers.IO.stub_stderr()
      assert Remove.execute(["poison"], %{wand_file: file}) == Error.get(:file_write_error)
    end

    test ":install_deps_error if cleaning the deps fails" do
      file = %WandFile{}
      Helpers.WandFile.stub_save(file)
      Helpers.System.stub_failed_cleanup_deps()
      Helpers.IO.stub_stderr()
      assert Remove.execute(["poison"], %{wand_file: file}) == Error.get(:install_deps_error)
    end
  end

  describe "execute successfully" do
    setup do
      Helpers.System.stub_cleanup_deps()
      :ok
    end

    test "Does nothing if the dependency is not being used" do
      file = %WandFile{}
      Helpers.WandFile.stub_save(file)
      assert Remove.execute(["poison"], %{wand_file: file}) == :ok
    end

    test "removes the dependency" do
      file = %WandFile{
        dependencies: [
          Helpers.WandFile.poison(),
          Helpers.WandFile.mox()
        ]
      }
      %WandFile{
        dependencies: [
          Helpers.WandFile.mox()
        ]
      }
      |> Helpers.WandFile.stub_save()

      assert Remove.execute(["poison"], %{wand_file: file}) == :ok
    end

    test "removes multiple dependencies" do
      file = %WandFile{
        dependencies: [
          Helpers.WandFile.poison(),
          Helpers.WandFile.mox()
        ]
      }

      Helpers.WandFile.stub_save(%WandFile{})
      assert Remove.execute(["mox", "poison", "not_present"], %{wand_file: file}) == :ok
    end
  end
end
