defmodule WandFileWithHelpTest do
  use ExUnit.Case, async: true
  import Mox
  import Wand.CLI.Errors, only: [error: 1]
  alias Wand.CLI.WandFileWithHelp
  alias Wand.WandFile
  alias Wand.Test.Helpers

  setup :verify_on_exit!

  describe "on success" do
    test "load returns {:ok, file}" do
      Helpers.WandFile.stub_load()
      assert WandFileWithHelp.load() == {:ok, %WandFile{}}
    end

    test "save returns :ok " do
      file = %WandFile{}
      Helpers.WandFile.stub_save(file)
      assert WandFileWithHelp.save(file) == :ok
    end
  end

  describe "load" do
    setup do
      Helpers.IO.stub_stderr()
      :ok
    end

    test ":enoent when failing to open" do
      Helpers.WandFile.stub_no_file()
      resp = WandFileWithHelp.load()
      assert resp == {:error, :wand_file_load, {:file_read_error, :enoent}}
      validate_error_handling(resp, :missing_wand_file)
    end

    test ":eaccess when there are no permissions" do
      Helpers.WandFile.stub_no_file(:eaccess)
      resp = WandFileWithHelp.load()
      assert resp == {:error, :wand_file_load, {:file_read_error, :eaccess}}
      validate_error_handling(resp, :missing_wand_file)
    end

    test ":invalid_wand_file when the JSON is invalid" do
      Helpers.WandFile.stub_invalid_file()
      resp = WandFileWithHelp.load()
      assert resp == {:error, :wand_file_load, :json_decode_error}
      validate_error_handling(resp, :invalid_wand_file)
    end

    test ":missing_version when the version is missing" do
      Helpers.WandFile.stub_file_missing_version()
      resp = WandFileWithHelp.load()
      assert resp == {:error, :wand_file_load, :missing_version}
      validate_error_handling(resp, :invalid_wand_file)
    end

    test ":invalid_version when the version is incorrect" do
      Helpers.WandFile.stub_file_wrong_version("not_a_version")
      resp = WandFileWithHelp.load()
      assert resp == {:error, :wand_file_load, :invalid_version}
      validate_error_handling(resp, :invalid_wand_file)
    end

    test ":version_mismatch when the version is too high" do
      Helpers.WandFile.stub_file_wrong_version("10.0.0")
      resp = WandFileWithHelp.load()
      assert resp == {:error, :wand_file_load, :version_mismatch}
      validate_error_handling(resp, :invalid_wand_file)
    end

    test ":invalid_dependencies when dependencies are missing" do
      Helpers.WandFile.stub_file_wrong_dependencies()
      resp = WandFileWithHelp.load()
      assert resp == {:error, :wand_file_load, :invalid_dependencies}
      validate_error_handling(resp, :invalid_wand_file)
    end

    test ":invalid_dependency when a dependency is invalid" do
      Helpers.WandFile.stub_file_bad_dependency()
      resp = WandFileWithHelp.load()
      assert resp == {:error, :wand_file_load, {:invalid_dependency, "mox"}}
      validate_error_handling(resp, :invalid_wand_file)
    end
  end

  describe "save errors" do
    setup do
      Helpers.IO.stub_stderr()
      :ok
    end
    test ":file_write_error when trying to save the file" do
      file = %WandFile{}
      Helpers.WandFile.stub_cannot_save(file)
      resp = WandFileWithHelp.save(file)
      assert resp == {:error, :wand_file_save, :enoent}
      validate_error_handling(resp, :file_write_error)
    end
  end

  defp validate_error_handling({:error, key, reason}, code) do
    assert WandFileWithHelp.handle_error(key, reason) == error(code)
  end
end
