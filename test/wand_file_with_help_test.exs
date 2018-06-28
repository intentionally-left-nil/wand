defmodule WandFileWithHelpTest do
  use ExUnit.Case, async: true
  import Mox
  import Wand.CLI.Errors, only: [error: 1]
  alias Wand.CLI.WandFileWithHelp
  alias Wand.WandFile
  alias Wand.Test.Helpers

  setup :verify_on_exit!

  test "load returns {:ok, file} on success" do
    Helpers.WandFile.stub_load()
    assert WandFileWithHelp.load() == {:ok, %WandFile{}}
  end

  test "load returns :wand_file_load on failure" do
    Helpers.WandFile.stub_no_file()
    assert WandFileWithHelp.load() == {:error, :wand_file_load, {:file_read_error, :enoent}}
  end

  test "save returns :ok on success" do
    file = %WandFile{}
    Helpers.WandFile.stub_save(file)
    assert WandFileWithHelp.save(file) == :ok
  end

  test "save returns :wand_file_save on failure" do
    file = %WandFile{}
    Helpers.WandFile.stub_cannot_save(file)
    assert WandFileWithHelp.save(file) == {:error, :wand_file_save, :enoent}
  end

  describe "read file errors" do
    setup do
      Helpers.IO.stub_stderr()
      :ok
    end

    test ":missing_wand_file when the file cannot be loaded" do
      assert WandFileWithHelp.handle_error(:wand_file_load, {:file_read_error, :enoent}) == error(:missing_wand_file)
    end

    test ":missing_wand_file when there are no permissions" do
      assert WandFileWithHelp.handle_error(:wand_file_load, {:file_read_error, :eaccess}) == error(:missing_wand_file)
    end

    test ":invalid_wand_file when the JSON is invalid" do
      assert WandFileWithHelp.handle_error(:wand_file_load, :json_decode_error) == error(:invalid_wand_file)
    end

    test ":invalid_wand_file when the version is missing" do
      assert WandFileWithHelp.handle_error(:wand_file_load, :missing_version) == error(:invalid_wand_file)
    end

    test ":invalid_wand_file when the version is incorrect" do
      assert WandFileWithHelp.handle_error(:wand_file_load, :invalid_version) == error(:invalid_wand_file)
    end

    test ":invalid_wand_file when the version is too high" do
    assert WandFileWithHelp.handle_error(:wand_file_load, :version_mismatch) == error(:invalid_wand_file)
    end

    test ":invalid_wand_file when dependencies are missing" do
      assert WandFileWithHelp.handle_error(:wand_file_load, :invalid_dependencies) == error(:invalid_wand_file)
    end

    test ":invalid_wand_file when a dependency is invalid" do
      assert WandFileWithHelp.handle_error(:wand_file_load, {:invalid_dependency, "poison@123"}) == error(:invalid_wand_file)
    end

    test ":file_write_error when trying to save the file" do
      assert WandFileWithHelp.handle_error(:wand_file_save, :enoent) == error(:file_write_error)
    end
  end
end
