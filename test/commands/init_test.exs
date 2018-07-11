defmodule InitTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.CLI.Executor.Result
  alias Wand.CLI.Commands.Init
  alias Wand.Test.Helpers
  alias WandCore.WandFile
  alias WandCore.WandFile.Dependency

  setup :verify_on_exit!

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
    test ":file_already_exists when the file already exists" do
      stub_exists("wand.json", true)
      assert Init.execute({"wand.json", []}) == {:error, :file_exists, "wand.json"}
    end

    test ":wand_core_api_error when get_deps fails" do
      stub_exists("wand.json", false)
      Helpers.System.stub_failed_get_deps()
      assert Init.execute({"wand.json", []}) == {:error, :get_deps, {1, ""}}
    end

    test ":wand_core_api_error when the dependency structure is bad" do
      stub_exists("wand.json", false)
      Helpers.System.stub_get_bad_deps()
      assert Init.execute({"wand.json", []}) == {:error, :get_deps, :invalid_dependency}
    end

    test ":mix_file_not_updated when the mix_file doesn't have deps" do
      stub_exists("./mix.exs", true)
      expect(WandCore.FileMock, :read, fn "./mix.exs" -> {:ok, "deps: deps(:prod)"} end)
      assert Init.after_save({"wand.json", []}) == {:error, :unable_to_modify_mix, nil}
    end

    test "Regression test: initialize a path with git" do
      stub_exists("wand.json", false)
      [
        ["wand_core", [["git", "https://github.com/AnilRedshift/wand-core.git"]]]
      ]
      |> Helpers.System.stub_get_deps()

      file = %WandFile{
        dependencies: [
          %Dependency{
            name: "wand_core",
            opts: %{git: "https://github.com/AnilRedshift/wand-core.git"}
          }
        ]
      }

      assert Init.execute({"wand.json", []}) == {:ok, expected_result(file)}
    end

    defp stub_exists(path, exists) do
      expect(WandCore.FileMock, :exists?, fn ^path -> exists end)
    end
  end

  describe "execute successfully" do
    test "initializes a file" do
      stub_exists("wand.json", false)
      Helpers.System.stub_get_deps()
      file = get_default_file()
      assert Init.execute({"wand.json", []}) == {:ok, expected_result(file)}
    end
  end

  defp expected_result(file) do
    %Result{
      wand_file: file,
      message: "Successfully initialized wand.json and copied your dependencies to it.\nType wand add [package] to add new packages, or wand upgrade to upgrade them\n"
    }
  end

  defp get_default_file() do
    dependencies = [
      %Dependency{name: "ex_doc", requirement: ">= 0.0.0", opts: %{only: :dev}},
      %Dependency{name: "mox", requirement: "~> 0.3.2", opts: %{only: :test}},
      %Dependency{name: "earmark", requirement: "~> 1.2"},
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
