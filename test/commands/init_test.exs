defmodule InitTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.CLI.Error
  alias Wand.CLI.Commands.Init
  alias Wand.Test.Helpers
  alias WandCore.WandFile
  alias Wand.CLI.Executor.Result
  alias WandCore.WandFile.Dependency

  describe "validate" do
    test "returns help if invalid flags are given" do
      assert Init.validate(["init", "--wrong-flag"]) == {:error, {:invalid_flag, "--wrong-flag"}}
    end

    test "initializes the current path if no args are given" do
      assert Init.validate(["init"]) == {:ok, {"wand.json", []}}
    end

    test "uses a custom path" do
      assert Init.validate(["init", "../foo"]) == {:ok, {"../foo/wand.json", []}}
    end

    test "uses a custom path that ends in wand.json" do
      assert Init.validate(["init", "../foo/wand.json"]) == {:ok, {"../foo/wand.json", []}}
    end

    test "passes in overwrite" do
      assert Init.validate(["init", "--overwrite"]) == {:ok, {"wand.json", [overwrite: true]}}
    end

    test "passes in force" do
      assert Init.validate(["init", "--overwrite"]) == {:ok, {"wand.json", [overwrite: true]}}
    end
  end

  describe "help" do
    setup :verify_on_exit!
    setup :stub_io

    test "invalid flag" do
      Init.help({:invalid_flag, "--wrong-flag"})
    end

    test "banner" do
      Init.help(:banner)
    end

    test "verbose" do
      Init.help(:verbose)
    end

    def stub_io(_) do
      expect(Wand.IOMock, :puts, fn _message -> :ok end)
      :ok
    end
  end

  describe "execute fails" do

    setup do
      Helpers.IO.stub_stderr()
      :ok
    end

    test ":file_already_exists when the file already exists" do
      stub_exists("wand.json", true)
      assert Init.execute({"wand.json", []}, %{}) == Error.get(:file_already_exists)
    end

    test ":file_write_error when saving the file" do
      stub_exists("wand.json", false)
      Helpers.System.stub_get_deps()
      file = get_default_file()
      Helpers.WandFile.stub_cannot_save(file)
      assert Init.execute({"wand.json", []}, %{}) == Error.get(:file_write_error)
    end

    test ":wand_core_api_error when get_deps fails" do
      stub_exists("wand.json", false)
      Helpers.System.stub_failed_get_deps()
      assert Init.execute({"wand.json", []}, %{}) == Error.get(:wand_core_api_error)
    end

    test ":wand_core_api_error when the dependency structure is bad" do
      stub_exists("wand.json", false)
      Helpers.System.stub_get_bad_deps()
      assert Init.execute({"wand.json", []}, %{}) == Error.get(:wand_core_api_error)
    end

    test ":mix_file_not_updated when the mix_file doesn't have deps" do
      stub_exists("wand.json", false)
      stub_exists("./mix.exs", true)
      expect(WandCore.FileMock, :read, fn "./mix.exs" -> {:ok, "deps: deps(:prod)"} end)
      Helpers.System.stub_get_deps()
      file = get_default_file()
      Helpers.WandFile.stub_save(file)
      assert Init.execute({"wand.json", []}, %{}) == Error.get(:mix_file_not_updated)
    end

    test "Regression test: initialize a path with git" do
      stub_exists("wand.json", false)
      stub_exists("./mix.exs", false)

      [
        ["wand_core", [["git", "https://github.com/AnilRedshift/wand-core.git"]]]
      ]
      |> Helpers.System.stub_get_deps()

      %WandFile{
        dependencies: [
          %Dependency{
            name: "wand_core",
            opts: %{git: "https://github.com/AnilRedshift/wand-core.git"}
          }
        ]
      }
      |> Helpers.WandFile.stub_save()

      assert Init.execute({"wand.json", []}, %{}) == Error.get(:mix_file_not_updated)
    end

    defp stub_exists(path, exists) do
      expect(WandCore.FileMock, :exists?, fn ^path -> exists end)
    end
  end

  describe "execute successfully" do
    setup do
      stub_exists("wand.json", false)
      stub_exists("./mix.exs", true)
      stub_read_mix_exs("./mix.exs")
      :ok
    end

    test "initializes a file" do
      Helpers.System.stub_get_deps()
      file = get_default_file()
      stub_all_writing("./mix.exs", "wand.json", file)

      message = "Successfully initialized wand.json and copied your dependencies to it.\nType wand add [package] to add new packages, or wand upgrade to upgrade them\n"
      assert Init.execute({"wand.json", []}, %{}) ==  {:ok, %Result{message: message}}
    end
  end

  defp get_default_file() do
    dependencies = [
      %Dependency{name: "earmark", requirement: "~> 1.2"},
      %Dependency{name: "ex_doc", requirement: ">= 0.0.0", opts: %{only: :dev}},
      %Dependency{name: "mox", requirement: "~> 0.3.2", opts: %{only: :test}}
    ]

    %WandFile{dependencies: dependencies}
  end

  defp stub_read_mix_exs(path) do
    expect(WandCore.FileMock, :read, fn ^path -> {:ok, "deps: deps(), app: :test"} end)
  end

  defp stub_all_writing(mix_path, wand_path, wand_file) do
    mix_contents = "deps: Mix.Tasks.WandCore.Deps.run([]), app: :test"
    wand_contents = wand_file |> WandCore.Poison.encode!(pretty: true)

    expect(WandCore.FileMock, :write, 2, fn
      ^mix_path, ^mix_contents -> :ok
      ^wand_path, ^wand_contents -> :ok
    end)
  end
end
