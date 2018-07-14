defmodule UpgradeTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.Test.Helpers
  alias Wand.CLI.Commands.Upgrade
  alias Wand.CLI.Commands.Upgrade.Options
  alias WandCore.WandFile
  alias WandCore.WandFile.Dependency
  alias Wand.CLI.Executor.Result

  setup :verify_on_exit!

  describe "validate" do
    test "returns help if invalid flags are given" do
      assert Upgrade.validate(["upgrade", "poison", "--wrong-flag"]) ==
               {:error, {:invalid_flag, "--wrong-flag"}}
    end

    test ":invalid_flag if --exact is given without --latest" do
      assert Upgrade.validate(["upgrade", "poison", "--exact"]) ==
               {:error, {:invalid_flag, "--exact"}}
    end

    test "a single package" do
      assert Upgrade.validate(["upgrade", "poison"]) == {:ok, {["poison"], %Options{}}}
    end

    test "Upgrade to the latest version" do
      assert Upgrade.validate(["upgrade", "poison", "--latest"]) ==
               {:ok, {["poison"], %Options{latest: true}}}
    end

    test "Upgrade to the latest prerelease version" do
      assert Upgrade.validate(["upgrade", "poison", "--latest", "--pre"]) ==
               {:ok, {["poison"], %Options{latest: true, pre: true}}}
    end

    test "Latest, using the exact version" do
      assert Upgrade.validate(["upgrade", "poison", "--exact", "--latest"]) ==
               {:ok, {["poison"], %Options{latest: true, mode: :exact}}}
    end

    test "If both tilde and exact are passed in, prefer exact" do
      assert Upgrade.validate(["upgrade", "poison", "--tilde", "--latest", "--exact"]) ==
               {:ok, {["poison"], %Options{latest: true, mode: :exact}}}
    end

    test "upgrade multiple packages" do
      assert Upgrade.validate(["upgrade", "poison", "ex_doc"]) ==
               {:ok, {["poison", "ex_doc"], %Options{}}}
    end

    test "upgrade all except" do
      assert Upgrade.validate(["upgrade", "--skip=poison", "--skip=cowboy"]) == {:ok, {:all, %Options{skip: ["poison", "cowboy"]}}}
    end

    test "upgrade all packages if none passed in" do
      assert Upgrade.validate(["upgrade"]) == {:ok, {:all, %Options{}}}
    end

    test "skip compiling" do
      assert Upgrade.validate(["upgrade", "poison", "--compile=false"]) ==
               {:ok, {["poison"], %Options{compile: false}}}
    end

    test "skip downloading" do
      assert Upgrade.validate(["upgrade", "poison", "--download=false"]) ==
               {:ok, {["poison"], %Options{download: false, compile: false}}}
    end
  end

  describe "help" do
    setup :verify_on_exit!
    setup :stub_io

    test "invalid_flag" do
      Upgrade.help({:invalid_flag, "--foobaz"})
    end

    test "banner" do
      Upgrade.help(:banner)
    end

    test "verbose" do
      Upgrade.help(:verbose)
    end

    def stub_io(_) do
      expect(Wand.IOMock, :puts, fn _message -> :ok end)
      :ok
    end
  end

  describe "execute" do
    test ":hex_api_error if getting the package from hex fails" do
      file = %WandFile{
        dependencies: [Helpers.WandFile.mox(), Helpers.WandFile.poison()]
      }

      Helpers.Hex.stub_not_found()

      assert Upgrade.execute({["poison"], %Options{skip: ["mox"]}}, %{wand_file: file}) ==
               {:error, :hex_api_error, {:not_found, "poison"}}
    end
  end

  describe "execute poison successfully" do
    test "No-ops if on the latest version" do
      validate(">= 2.2.0 and < 3.0.0")
    end

    test "No-ops if there are no matching releases" do
      validate(">= 4.2.0 and < 5.0.0")
    end

    test "No-ops a custom environment" do
      validate("== 3.2.0 or ==3.2.0--dev", no_hex: true)
    end

    test "No-ops an exact match" do
      validate("== 3.2.0", no_hex: true)
    end

    test "No-ops if the package is skipped" do
        validate("~> 1.5.0", "~> 1.5.0", %Options{skip: ["poison"]}, no_hex: true)
    end

    test "Updates a tilde match" do
      validate("~> 1.5.0", "~> 1.5.2")
    end

    test "Updates a caret match" do
      validate(" >= 1.2.1 and < 2.0.0", ">= 1.5.2 and < 2.0.0")
    end

    test "No-ops a patch caret match" do
      validate(">= 0.0.3 and <= 0.0.3")
    end

    test "No-ops with --latest if on the newest version" do
      validate(">= 3.1.0 and < 4.0.0", %Options{latest: true})
    end

    test "Updates to the latest tilde with --latest" do
      validate("~> 1.2.0", "~> 3.1.0", %Options{latest: true, mode: :tilde})
    end

    test "Updates to the latest exact with --latest" do
      validate("~> 1.2.0", "== 3.1.0", %Options{latest: true, mode: :exact})
    end

    test "Updates to the latest caret with --latest" do
      validate("~> 1.2.0", ">= 3.1.0 and < 4.0.0", %Options{latest: true, mode: :caret})
    end

    test "Does not update to a beta version" do
      validate("~> 1.4.0", "~> 1.4.1")
    end

    test "Updates to a pre version" do
      validate("~> 1.4.0", "~> 1.4.2-dev2", %Options{pre: true})
    end

    test "Updates a custom to the latest caret with --latest" do
      validate("~> 1.2.0-dev and != 1.2.1", ">= 3.1.0 and < 4.0.0", %Options{
        latest: true,
        mode: :caret
      })
    end

    defp validate(requirement), do: validate(requirement, requirement, %Options{})

    defp validate(requirement, no_hex: true),
      do: validate(requirement, requirement, %Options{}, no_hex: true)

    defp validate(requirement, %Options{} = options),
      do: validate(requirement, requirement, options)

    defp validate(requirement, expected), do: validate(requirement, expected, %Options{})

    defp validate(requirement, expected, options, test_flags \\ []) do
      file = %WandFile{
        dependencies: [
          %Dependency{name: "poison", requirement: requirement}
        ]
      }

      expected = %WandFile{
        dependencies: [
          %Dependency{name: "poison", requirement: expected}
        ]
      }

      unless test_flags[:no_hex] do
        Helpers.Hex.stub_poison()
      end

      assert Upgrade.execute({["poison"], options}, %{wand_file: file}) ==
               {:ok, %Result{wand_file: expected}}
    end
  end

  describe "execute with git dependencies" do
    test "No-ops if git without a requirement" do
      file = %WandFile{
        dependencies: [
          %Dependency{name: "poison", opts: %{git: "https://github.com/devinus/poison.git"}}
        ]
      }

      assert Upgrade.execute({["poison"], %Options{}}, %{wand_file: file}) ==
               {:ok, %Result{wand_file: file}}
    end
  end

  describe "execute with file dependencies" do
    test "No-ops" do
      file = %WandFile{
        dependencies: [
          %Dependency{name: "poison", opts: %{path: "../poison"}}
        ]
      }

      assert Upgrade.execute({["poison"], %Options{}}, %{wand_file: file}) ==
               {:ok, %Result{wand_file: file}}
    end
  end

  test "upgrade all, except" do
    file = %WandFile{
      dependencies: [Helpers.WandFile.mox(), Helpers.WandFile.poison()]
    }
    Helpers.Hex.stub_poison()
    assert Upgrade.execute({:all, %Options{skip: ["mox"]}}, %{wand_file: file}) == {:ok, %Result{wand_file: file}}
  end

  describe "after_save" do
    test "skips downloading if download: false is set" do
      assert Upgrade.after_save({["poison"], %Options{download: false, compile: false}}) == :ok
    end

    test ":install_deps_error when downloading fails" do
      Helpers.System.stub_failed_update_deps()
      assert Upgrade.after_save({["poison"], %Options{}}) == {:error, :install_deps_error, :download_failed}
    end

    test "skips compiling if compile: false is set" do
      Helpers.System.stub_update_deps()
        assert Upgrade.after_save({["poison"], %Options{compile: false}}) == :ok
    end

    test "downloads and compiles" do
      Helpers.System.stub_update_deps()
      Helpers.System.stub_compile()
        assert Upgrade.after_save({["poison"], %Options{}}) == :ok
    end
  end

  test "handle_error" do
    Upgrade.handle_error(:hex_api_error, {:not_found, "poison"})
  end
end
