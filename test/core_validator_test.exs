defmodule CoreValidatorTest do
  use ExUnit.Case, async: true
  alias Wand.CLI.CoreValidator
  alias Wand.Test.Helpers
  import Mox
  import Wand.CLI.Errors, only: [error: 1]

  describe "require_core" do
    test ":missing_core if the core is not available" do
      Helpers.System.stub_core_version_missing()
      assert CoreValidator.require_core() == {:error, :require_core, :missing_core}
    end

    test ":version_mismatch if the the core version is too low" do
      Helpers.System.stub_core_version("0.0.2")
      assert CoreValidator.require_core() == {:error, :require_core, {:version_mismatch, "0.0.2"}}
    end

    test "version mismatch if the core version is too high" do
      Helpers.System.stub_core_version("5.0.2")
      assert CoreValidator.require_core() == {:error, :require_core, {:version_mismatch, "5.0.2"}}
    end

    test ":ok on succes" do
      version = Wand.version()
      Helpers.System.stub_core_version(version)
      assert CoreValidator.require_core() == :ok
    end
  end

  describe "handle_error" do
    setup :verify_on_exit!

    setup do
      Helpers.IO.stub_stderr()
      :ok
    end

    test ":wand_core_missing" do
      assert CoreValidator.handle_error(:require_core, :missing_core) == error(:wand_core_missing)
    end

    test ":bad_wand_core_version" do
      assert CoreValidator.handle_error(:require_core, {:version_mismatch, "0.4.3"}) ==
               error(:bad_wand_core_version)
    end
  end
end
