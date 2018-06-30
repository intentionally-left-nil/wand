defmodule UpgradeTest do
  use ExUnit.Case, async: true
  import Mox
  import Wand.CLI.Errors, only: [error: 1]
  alias Wand.Test.Helpers
  alias Wand.CLI.Commands.Upgrade
  alias Wand.CLI.Commands.Upgrade.Options
  alias WandCore.WandFile
  alias WandCore.WandFile.Dependency

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
    test ":missing_wand_file if cannot open wand file" do
      Helpers.WandFile.stub_no_file()
      Helpers.IO.stub_stderr()
      assert Upgrade.execute({["poison"], %Options{}}) == error(:missing_wand_file)
    end

    test ":package_not_found if the package is not in wand.json" do
      Helpers.WandFile.stub_load()
      Helpers.IO.stub_stderr()
      assert Upgrade.execute({["poison"], %Options{}}) == error(:package_not_found)
    end

    test ":hex_api_error if getting the package from hex fails" do
      file = %WandFile{
        dependencies: [Helpers.WandFile.poison()]
      }

      Helpers.WandFile.stub_load(file)
      Helpers.IO.stub_stderr()
      Helpers.Hex.stub_not_found()

      assert Upgrade.execute({["poison"], %Options{}}) == error(:hex_api_error)
    end

    test "Error saving the wand file" do
      file = %WandFile{}
      Helpers.WandFile.stub_load(file)
      Helpers.WandFile.stub_cannot_save(file)
      Helpers.IO.stub_stderr()
      assert Upgrade.execute({:all, %Options{}}) == error(:file_write_error)
    end

    test "update all no-ops if the dependencies are empty" do
      file = %WandFile{}
      Helpers.WandFile.stub_load(file)
      Helpers.WandFile.stub_save(file)
      assert Upgrade.execute({:all, %Options{}}) == :ok
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
      validate("== 3.2.0 or ==3.2.0--dev")
    end

    test "No-ops an exact match" do
      validate("== 3.2.0")
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

    test "Updates a custom to the latest caret with --latest" do
      validate("~> 1.2.0-dev and != 1.2.1", ">= 3.1.0 and < 4.0.0", %Options{
        latest: true,
        mode: :caret
      })
    end

    defp validate(requirement), do: validate(requirement, requirement, %Options{})

    defp validate(requirement, %Options{} = options),
      do: validate(requirement, requirement, options)

    defp validate(requirement, expected), do: validate(requirement, expected, %Options{})

    defp validate(requirement, expected, options) do
      %WandFile{
        dependencies: [
          %Dependency{name: "poison", requirement: requirement}
        ]
      }
      |> Helpers.WandFile.stub_load()

      %WandFile{
        dependencies: [
          %Dependency{name: "poison", requirement: expected}
        ]
      }
      |> Helpers.WandFile.stub_save()

      Helpers.Hex.stub_poison()
      assert Upgrade.execute({["poison"], options}) == :ok
    end
  end
end
