defmodule AddExecuteTest do
  use ExUnit.Case
  import Mox
  alias Wand.CLI.Error
  alias Wand.CLI.Commands.Add
  alias Wand.CLI.Commands.Add.{Git, Hex, Package, Path}
  alias Wand.Test.Helpers
  alias WandCore.WandFile
  alias WandCore.WandFile.Dependency

  setup :verify_on_exit!
  setup :set_mox_global

  @poison %Package{name: "poison"}

  describe "load/save errors" do
    test "Error loading the wand file" do
      Helpers.WandFile.stub_no_file()
      Helpers.IO.stub_stderr()
      assert Add.execute([@poison]) == Error.get(:missing_wand_file)
    end

    test "Error saving the wand file" do
      Helpers.WandFile.stub_load()

      get_file()
      |> Helpers.WandFile.stub_cannot_save()

      Helpers.IO.stub_stderr()
      assert Add.execute([get_package()]) == Error.get(:file_write_error)
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
      assert Add.execute([@poison]) == Error.get(:package_not_found)
    end

    test ":hex_api_error if there is no internet" do
      Helpers.Hex.stub_no_connection()
      assert Add.execute([@poison]) == Error.get(:hex_api_error)
    end

    test ":hex_api_error if hex returns :bad_response" do
      Helpers.Hex.stub_bad_response()
      assert Add.execute([@poison]) == Error.get(:hex_api_error)
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
          %Dependency{name: "poison", requirement: "~> 3.1"}
        ]
      }
      |> Helpers.WandFile.stub_load()

      assert Add.execute([@poison]) == Error.get(:package_already_exists)
    end

    test ":package_already_exists when trying to add the same package twice" do
      Helpers.WandFile.stub_load()
      Helpers.Hex.stub_poison()
      assert Add.execute([@poison, @poison]) == Error.get(:package_already_exists)
    end
  end

  describe "download" do
    test ":install_deps_error when downloading fails" do
      Helpers.WandFile.stub_load()
      stub_file()
      Helpers.System.stub_failed_update_deps()
      Helpers.IO.stub_stderr()
      package = get_package()
      assert Add.execute([package]) == Error.get(:install_deps_error)
    end

    test "skips downloading if download: false is set" do
      Helpers.WandFile.stub_load()
      stub_file()
      package = get_package(download: false, compile: false)
      assert Add.execute([package]) |> elem(0) == :ok
    end
  end

  describe "compile" do
    test ":install_deps_error when compiling fails" do
      Helpers.WandFile.stub_load()
      stub_file()
      Helpers.System.stub_update_deps()
      Helpers.System.stub_failed_compile()
      Helpers.IO.stub_stderr()
      package = get_package(compile_env: :prod)
      assert Add.execute([package]) == Error.get(:install_deps_error)
    end

    test "skips compiling if compile: false is set" do
      Helpers.WandFile.stub_load()
      stub_file()
      Helpers.System.stub_update_deps()
      package = get_package(compile: false)
      assert Add.execute([package]) |> elem(0) == :ok
    end
  end

  describe "Successfully" do
    setup do
      Helpers.WandFile.stub_load()
      Helpers.System.stub_update_deps()
      Helpers.System.stub_compile()
      :ok
    end

    test "adds a single package" do
      Helpers.Hex.stub_poison()
      stub_file(requirement: ">= 3.1.0 and < 4.0.0")
      assert Add.execute([@poison]) |> elem(0) == :ok
    end

    test "add a package with a version" do
      stub_file()
      package = get_package()
      assert Add.execute([package]) == {:ok, "Succesfully added poison: >= 3.1.3 and < 4.0.0"}
    end

    test "add two packages" do
      %WandFile{
        dependencies: [
          %Dependency{name: "mox", requirement: ">= 3.1.3 and < 4.0.0"},
          %Dependency{name: "poison", requirement: ">= 3.1.3 and < 4.0.0"}
        ]
      }
      |> Helpers.WandFile.stub_save()

      poison = get_package()
      mox = get_named_package("mox")

      assert Add.execute([poison, mox]) ==
               {:ok,
                "Succesfully added poison: >= 3.1.3 and < 4.0.0\nSuccesfully added mox: >= 3.1.3 and < 4.0.0"}
    end

    test "add a package with the exact version" do
      stub_file(requirement: "== 3.1.2")
      package = get_package(requirement: "== 3.1.2")
      assert Add.execute([package]) |> elem(0) == :ok
    end

    test "add a package with the compile_env flag" do
      stub_file(opts: %{compile_env: :test})
      package = get_package(compile_env: :test)
      assert Add.execute([package]) |> elem(0) == :ok
    end

    test "does not add compile_env if it's set to prod" do
      stub_file()
      package = get_package(compile_env: :prod)
      assert Add.execute([package]) |> elem(0) == :ok
    end

    test "add the latest version only to test and dev" do
      stub_file(requirement: ">= 3.1.0 and < 4.0.0", opts: %{only: [:test, :dev]})
      Helpers.Hex.stub_poison()
      package = get_package(only: [:test, :dev], requirement: {:latest, :caret})
      assert Add.execute([package]) |> elem(0) == :ok
    end

    test "add the optional, override, and runtime flag if set" do
      stub_file(opts: %{optional: true, override: true, runtime: false, read_app_file: false})
      package = get_package(optional: true, override: true, runtime: false, read_app_file: false)
      assert Add.execute([package]) |> elem(0) == :ok
    end

    test "no opts for remaining opts if default" do
      stub_file()
      package = get_package(optional: false, override: false, runtime: true, read_app_file: true)
      assert Add.execute([package]) |> elem(0) == :ok
    end

    test "add a git package with all the fixings" do
      stub_file(
        opts: %{
          git: "https://github.com/devinus/poison.git",
          ref: "master",
          sparse: true,
          submodules: "myfolder"
        }
      )

      package =
        get_package(
          details: %Git{
            git: "https://github.com/devinus/poison.git",
            ref: "master",
            sparse: true,
            submodules: "myfolder"
          }
        )

      assert Add.execute([package]) |> elem(0) == :ok
    end

    test "do not add extra git flags" do
      stub_file(opts: %{git: "https://github.com/devinus/poison.git"})

      package =
        get_package(
          details: %Git{
            git: "https://github.com/devinus/poison.git",
            ref: nil,
            sparse: nil,
            submodules: false
          }
        )

      assert Add.execute([package]) |> elem(0) == :ok
    end

    test "add a path with an umbrella" do
      stub_file(opts: %{path: "/path/to/app", in_umbrella: true, optional: true})

      package =
        get_package(details: %Path{path: "/path/to/app", in_umbrella: true}, optional: true)

      assert Add.execute([package]) |> elem(0) == :ok
    end

    test "do not include umbrella if false" do
      stub_file(opts: %{path: "/path/to/app"})
      package = get_package(details: %Path{path: "/path/to/app", in_umbrella: false})
      assert Add.execute([package]) |> elem(0) == :ok
    end

    test "add a hex package with all the fixings" do
      stub_file(opts: %{hex: "mypoison", organization: "evilcorp", repo: "nothexpm"})

      package =
        get_package(details: %Hex{hex: "mypoison", organization: "evilcorp", repo: "nothexpm"})

      assert Add.execute([package]) |> elem(0) == :ok
    end
  end

  defp get_package(opts \\ []), do: get_named_package("poison", opts)

  def get_named_package(name, opts \\ []) do
    fields =
      %Package{}
      |> Map.to_list()
      |> Keyword.merge(
        name: name,
        requirement: ">= 3.1.3 and < 4.0.0"
      )
      |> Keyword.merge(opts)

    struct(Package, fields)
  end

  defp get_file(opts \\ []) do
    fields =
      %Dependency{name: "poison", requirement: ">= 3.1.3 and < 4.0.0"}
      |> Map.to_list()
      |> Keyword.merge(opts)

    dependency = struct(Dependency, fields)
    %WandFile{dependencies: [dependency]}
  end

  defp stub_file(opts \\ []) do
    get_file(opts)
    |> Helpers.WandFile.stub_save()
  end
end
