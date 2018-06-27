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

  describe "read file errors" do
    setup do
      Helpers.IO.stub_stderr()
      :ok
    end

    test ":missing_wand_file when the file cannot be loaded" do
      Helpers.WandFile.stub_no_file()
      assert Add.execute([%Package{name: "poison"}]) == error(:missing_wand_file)
    end

    test ":missing_wand_file when there are no permissions" do
      Helpers.WandFile.stub_no_file(:eaccess)
      assert Add.execute([%Package{name: "poison"}]) == error(:missing_wand_file)
    end

    test ":invalid_wand_file when the JSON is invalid" do
      Helpers.WandFile.stub_invalid_file()
      assert Add.execute([%Package{name: "poison"}]) == error(:invalid_wand_file)
    end

    test ":invalid_wand_file when the version is missing" do
      Helpers.WandFile.stub_file_missing_version()
      assert Add.execute([%Package{name: "poison"}]) == error(:invalid_wand_file)
    end

    test ":invalid_wand_file when the version is incorrect" do
      Helpers.WandFile.stub_file_wrong_version("not_a_version")
      assert Add.execute([%Package{name: "poison"}]) == error(:invalid_wand_file)
    end

    test ":invalid_wand_file when the version is too high" do
      Helpers.WandFile.stub_file_wrong_version("10.0.0")
      assert Add.execute([%Package{name: "poison"}]) == error(:invalid_wand_file)
    end

    test ":invalid_wand_file when dependencies are missing" do
      Helpers.WandFile.stub_file_wrong_dependencies()
      assert Add.execute([%Package{name: "poison"}]) == error(:invalid_wand_file)
    end

    test ":invalid_wand_file when a dependency is invalid" do
      Helpers.WandFile.stub_file_bad_dependency()
        assert Add.execute([%Package{name: "poison"}]) == error(:invalid_wand_file)
    end
  end

  describe "hex api errors" do
    setup do
      Helpers.WandFile.stub_empty()
      Helpers.IO.stub_stderr()
      :ok
    end

    test ":package_not_found when the package is not in hex" do
      Helpers.Hex.stub_not_found()
      assert Add.execute([%Package{name: "poison"}]) == error(:package_not_found)
    end

    test ":hex_api_error if there is no internet" do
      Helpers.Hex.stub_no_connection()
      assert Add.execute([%Package{name: "poison"}]) == error(:hex_api_error)
    end

    test ":hex_api_error if hex returns :bad_response" do
      Helpers.Hex.stub_bad_response()
      assert Add.execute([%Package{name: "poison"}]) == error(:hex_api_error)
    end
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
