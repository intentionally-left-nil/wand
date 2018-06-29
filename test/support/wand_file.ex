defmodule Wand.Test.Helpers.WandFile do
  import Mox
  alias WandCore.WandFile
  alias WandCore.WandFile.Dependency

  def stub_load(file \\ %WandFile{}) do
    file
    |> WandCore.Poison.encode!(pretty: true)
    |> stub_read()
  end

  def stub_save(file) do
    contents = file |> WandCore.Poison.encode!(pretty: true)
    expect(WandCore.FileMock, :write, fn _path, ^contents -> :ok end)
  end

  def poison() do
    %Dependency{name: "poison", requirement: ">= 3.1.3 and < 4.0.0"}
  end

  def mox() do
    %Dependency{name: "mox", requirement: ">= 0.3.2 and < 0.4.0", opts: %{only: [:test]}}
  end

  def stub_cannot_save(file, reason \\ :enoent) do
    contents = file |> WandCore.Poison.encode!(pretty: true)
    expect(WandCore.FileMock, :write, fn _path, ^contents -> {:error, reason} end)
  end

  def stub_no_file(reason \\ :enoent) do
    expect(WandCore.FileMock, :read, fn _path -> {:error, reason} end)
  end

  def stub_invalid_file() do
    stub_read("[ NOT VALID JSON")
  end

  def stub_file_wrong_dependencies() do
    contents =
      %{
        version: "1.0.0",
        dependencies: "not requirements"
      }
      |> WandCore.Poison.encode!(pretty: true)

    stub_read(contents)
  end

  def stub_file_bad_dependency() do
    contents =
      %{
        version: "1.0.0",
        dependencies: %{
          mox: "== == 1.0.0"
        }
      }
      |> WandCore.Poison.encode!(pretty: true)

    expect(WandCore.FileMock, :read, fn _path -> {:ok, contents} end)
  end

  def stub_file_wrong_version(version) do
    contents =
      %{
        version: version,
        requirements: []
      }
      |> WandCore.Poison.encode!(pretty: true)

    stub_read(contents)
  end

  def stub_file_missing_version() do
    contents =
      %{
        requirements: []
      }
      |> WandCore.Poison.encode!(pretty: true)

    stub_read(contents)
  end

  defp stub_read(contents) do
    expect(WandCore.FileMock, :read, fn _path -> {:ok, contents} end)
  end
end
