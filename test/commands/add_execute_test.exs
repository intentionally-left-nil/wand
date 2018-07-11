defmodule AddExecuteTest do
  use ExUnit.Case
  import Mox
  alias Wand.CLI.Error
  alias Wand.CLI.Commands.Add
  alias Wand.CLI.Commands.Add.{Git, Hex, Package, Path}
  alias Wand.Test.Helpers
  alias WandCore.WandFile
  alias WandCore.WandFile.Dependency
  alias Wand.CLI.Executor.Result

  setup :verify_on_exit!
  setup :set_mox_global

  @poison %Package{name: "poison"}

  describe "hex api errors" do
    test ":package_not_found when the package is not in hex" do
      Helpers.Hex.stub_not_found()
      assert Add.execute([@poison], extras()) == {:error, :dependency, {:not_found, "poison"}}
    end

    test ":hex_api_error if there is no internet" do
      Helpers.Hex.stub_no_connection()
      assert Add.execute([@poison], extras()) == {:error, :dependency, {:no_connection, "poison"}}
    end

    test ":hex_api_error if hex returns :bad_response" do
      Helpers.Hex.stub_bad_response()
      assert Add.execute([@poison], extras()) == {:error, :dependency, {:bad_response, "poison"}}
    end
  end

  describe "dependency errors" do
    setup do
      Helpers.Hex.stub_poison()
      :ok
    end

    test ":package_already_exists when poison already exists" do
      file = %WandFile{
        dependencies: [
          %Dependency{name: "poison", requirement: "~> 3.1"}
        ]
      }

      assert Add.execute([@poison], extras(file)) == {:error, :add_dependency, {:already_exists, "poison"}}
    end

    test ":package_already_exists when trying to add the same package twice" do
      Helpers.Hex.stub_poison()
      assert Add.execute([@poison, @poison], extras()) == {:error, :add_dependency, {:already_exists, "poison"}}
    end
  end

  describe "after_save" do
    test ":install_deps_error when downloading fails" do
      Helpers.System.stub_failed_update_deps()
      package = get_package()
      assert Add.after_save([package]) == {:error, :download_failed, {1, "Could not find a Mix.Project, please ensure you are running Mix in a directory with a mix.exs file"}}
    end

    test "skips downloading if download: false is set" do
      package = get_package(download: false, compile: false)
      assert Add.after_save([package]) == :ok
    end

    test ":install_deps_error when compiling fails" do
      Helpers.System.stub_update_deps()
      Helpers.System.stub_failed_compile()
      package = get_package(compile_env: :prod)
      assert Add.after_save([package]) == {:error, :compile_failed, {1, "** (SyntaxError) mix.exs:9"}}
    end

    test "skips compiling if compile: false is set" do
      Helpers.System.stub_update_deps()
      package = get_package(compile: false)
      assert Add.after_save([package]) == :ok
    end

  end

  describe "Successfully" do
    defp validate(packages, expected_file \\ get_file()) do
      result = Add.execute(packages, extras())
      assert elem(result, 0) == :ok
      {:ok, %Result{wand_file: actual_file}} = result
      assert actual_file == expected_file
      result
    end

    test "adds a single package" do
      Helpers.Hex.stub_poison()
      expected_file = get_file(requirement: ">= 3.1.0 and < 4.0.0")
      validate([@poison], expected_file)
    end

    test "add a package with a version" do
      validate([get_package()])
    end

    test "add two packages" do
      file = %WandFile{
        dependencies: [
          %Dependency{name: "mox", requirement: ">= 3.1.3 and < 4.0.0"},
          %Dependency{name: "poison", requirement: ">= 3.1.3 and < 4.0.0"}
        ]
      }

      packages = [get_package(), get_named_package("mox")]
      {:ok, result} = validate(packages, file)
      assert result.message == "Succesfully added poison: >= 3.1.3 and < 4.0.0\nSuccesfully added mox: >= 3.1.3 and < 4.0.0"
    end

    test "add a package with the exact version" do
      file = get_file(requirement: "== 3.1.2")
      validate([get_package(requirement: "== 3.1.2")], file)
    end

    test "add a package with the compile_env flag" do
      file = get_file(opts: %{compile_env: :test})
      validate([get_package(compile_env: :test)], file)
    end

    test "does not add compile_env if it's set to prod" do
      validate([get_package(compile_env: :prod)])
    end

    test "add the latest version only to test and dev" do
      file = get_file(requirement: ">= 3.1.0 and < 4.0.0", opts: %{only: [:test, :dev]})
      Helpers.Hex.stub_poison()
      package = get_package(only: [:test, :dev], requirement: {:latest, :caret})
      validate([package], file)
    end

    test "add the optional, override, and runtime flag if set" do
      file = get_file(opts: %{optional: true, override: true, runtime: false, read_app_file: false})
      package = get_package(optional: true, override: true, runtime: false, read_app_file: false)
      validate([package], file)
    end

    test "no opts for remaining opts if default" do
      package = get_package(optional: false, override: false, runtime: true, read_app_file: true)
      validate([package])
    end

    test "add a git package with all the fixings" do
      file = get_file(
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
      validate([package], file)
    end

    test "do not add extra git flags" do
      file = get_file(opts: %{git: "https://github.com/devinus/poison.git"})

      package =
        get_package(
          details: %Git{
            git: "https://github.com/devinus/poison.git",
            ref: nil,
            sparse: nil,
            submodules: false
          }
        )
      validate([package], file)
    end

    test "add a path with an umbrella" do
      file = get_file(opts: %{path: "/path/to/app", in_umbrella: true, optional: true})

      package =
        get_package(details: %Path{path: "/path/to/app", in_umbrella: true}, optional: true)

      validate([package], file)
    end

    test "do not include umbrella if false" do
      file = get_file(opts: %{path: "/path/to/app"})
      package = get_package(details: %Path{path: "/path/to/app", in_umbrella: false})
      validate([package], file)
    end

    test "add a hex package with all the fixings" do
      file = get_file(opts: %{hex: "mypoison", organization: "evilcorp", repo: "nothexpm"})

      package =
        get_package(details: %Hex{hex: "mypoison", organization: "evilcorp", repo: "nothexpm"})
      validate([package], file)
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

  defp extras(file \\ %WandFile{}) do
    %{wand_file: file}
  end
end
