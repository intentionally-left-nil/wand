defmodule DependencyDownloaderTest do
  use ExUnit.Case, async: true
  alias Wand.Test.Helpers
  alias Wand.CLI.DependencyDownloader
  import Mox

  setup :verify_on_exit!

  describe "download" do
    test ":install_deps_error when downloading fails" do
      Helpers.System.stub_failed_update_deps()
      assert DependencyDownloader.download() == {:error, :install_deps_error, :download_failed}
    end

    test ":ok when downloaing succeeds" do
      Helpers.System.stub_update_deps()
      assert DependencyDownloader.download() == :ok
    end

    test "handle_error" do
      DependencyDownloader.handle_error(:install_deps_error, :download_failed)
    end
  end

  describe "compile" do
    test ":install_deps_error when compiling fails" do
      Helpers.System.stub_failed_compile()
      assert DependencyDownloader.compile() == {:error, :install_deps_error, :compile_failed}
    end

    test ":ok when compiling succeeds" do
      Helpers.System.stub_compile()
      assert DependencyDownloader.compile() == :ok
    end

    test "handle_error" do
      DependencyDownloader.handle_error(:install_deps_error, :compile_failed)
    end
  end
end
