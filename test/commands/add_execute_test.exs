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

  @poison %Package{name: "poison"}

  describe "read file errors" do
    setup do
      Helpers.IO.stub_stderr()
      :ok
    end

    test ":missing_wand_file when the file cannot be loaded" do
      Helpers.WandFile.stub_no_file()
      assert Add.execute([@poison]) == error(:missing_wand_file)
    end

    test ":missing_wand_file when there are no permissions" do
      Helpers.WandFile.stub_no_file(:eaccess)
      assert Add.execute([@poison]) == error(:missing_wand_file)
    end

    test ":invalid_wand_file when the JSON is invalid" do
      Helpers.WandFile.stub_invalid_file()
      assert Add.execute([@poison]) == error(:invalid_wand_file)
    end

    test ":invalid_wand_file when the version is missing" do
      Helpers.WandFile.stub_file_missing_version()
      assert Add.execute([@poison]) == error(:invalid_wand_file)
    end

    test ":invalid_wand_file when the version is incorrect" do
      Helpers.WandFile.stub_file_wrong_version("not_a_version")
      assert Add.execute([@poison]) == error(:invalid_wand_file)
    end

    test ":invalid_wand_file when the version is too high" do
      Helpers.WandFile.stub_file_wrong_version("10.0.0")
      assert Add.execute([@poison]) == error(:invalid_wand_file)
    end

    test ":invalid_wand_file when dependencies are missing" do
      Helpers.WandFile.stub_file_wrong_dependencies()
      assert Add.execute([@poison]) == error(:invalid_wand_file)
    end

    test ":invalid_wand_file when a dependency is invalid" do
      Helpers.WandFile.stub_file_bad_dependency()
        assert Add.execute([@poison]) == error(:invalid_wand_file)
    end
  end

  describe "hex api errors" do
    setup do
      Helpers.WandFile.stub_load()
      Helpers.IO.stub_stderr()
      :ok
    end

    test ":package_not_found when the package is not in hex" do
      Helpers.Hex.stub_not_found()
      assert Add.execute([@poison]) == error(:package_not_found)
    end

    test ":hex_api_error if there is no internet" do
      Helpers.Hex.stub_no_connection()
      assert Add.execute([@poison]) == error(:hex_api_error)
    end

    test ":hex_api_error if hex returns :bad_response" do
      Helpers.Hex.stub_bad_response()
      assert Add.execute([@poison]) == error(:hex_api_error)
    end
  end

  describe "dependency errors" do
    setup do
      Helpers.IO.stub_stderr()
      Helpers.Hex.stub_poison()
      :ok
    end

    test ":package_already_exists when poison already exists" do
      %WandFile{
        dependencies: [
          %Dependency{name: "poison", requirement: "~> 3.1"},
        ]
      }
      |> Helpers.WandFile.stub_load()
      assert Add.execute([@poison]) == error(:package_already_exists)
    end

    test ":package_already_exists when trying to add the same package twice" do
      Helpers.WandFile.stub_load()
      Helpers.Hex.stub_poison()
        assert Add.execute([@poison, @poison]) == error(:package_already_exists)
    end

    test ":file_write_error when trying to save the file" do
      Helpers.WandFile.stub_load()
      %WandFile{
        dependencies: [%Dependency{name: "poison", requirement: "~> 3.1.0"}]
      }
      |> Helpers.WandFile.stub_cannot_save()
      assert Add.execute([@poison]) == error(:file_write_error)
    end
  end

  test "adds a single package" do
    Helpers.WandFile.stub_load()
    Helpers.Hex.stub_poison()
    %WandFile{
      dependencies: [%Dependency{name: "poison", requirement: "~> 3.1.0"}]
    }
    |> Helpers.WandFile.stub_save()
    assert Add.execute([@poison]) == :ok
  end

  test "add a package with a version" do
    Helpers.WandFile.stub_load()
    %WandFile{
      dependencies: [%Dependency{name: "poison", requirement: "~> 3.1.3"}]
    }
    |> Helpers.WandFile.stub_save()
    package = %Package{name: "poison", requirement: "3.1.3"}
    assert Add.execute([package]) == :ok
  end

  test "add a package with the exact version" do
    Helpers.WandFile.stub_load()
    %WandFile{
      dependencies: [%Dependency{name: "poison", requirement: "== 3.1.2"}]
    }
    |> Helpers.WandFile.stub_save()
    package = %Package{name: "poison", requirement: "3.1.2", mode: :exact}
    assert Add.execute([package]) == :ok

  end
end
