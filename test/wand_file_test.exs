defmodule WandFileTest do
  use ExUnit.Case
  import Mox
  alias Wand.WandFile

  describe "load" do
    test "loads the default wand.json file" do
      stub_read_valid()
      assert WandFile.load() == {:ok, valid_deps_config()}
    end

    test "loads a given path" do
      stub_read_valid("/path/to/wand.json")
      assert WandFile.load("/path/to/wand.json") == {:ok, valid_deps_config()}
    end

    test "returns an error if not found" do
      stub_not_found()
      assert WandFile.load() == {:error, :enoent}
    end

    test "returns an error if not valid JSON" do
      stub_read(:ok, "wand.json", "[ NOT VALID JSON")
      assert WandFile.load() == {:error, {:invalid, "N", 2}}
    end

    test ":missing_version if the version is missing" do
      stub_read(:ok, "wand.json", "{\"dependencies\": {}}")
      assert WandFile.load() == {:error, :missing_version}
    end

    test ":invalid_version if the version is nil" do
      json = Poison.encode!(%{version: nil, dependencies: %{}})
      stub_read(:ok, "wand.json", json)
      assert WandFile.load() == {:error, :invalid_version}
    end

    test ":invalid version if the version is bad" do
      json = Poison.encode!(%{version: "1.0", dependencies: %{}})
      stub_read(:ok, "wand.json", json)
      assert WandFile.load() == {:error, :invalid_version}
    end

    test ":version_mismatch if the version is too high" do
      json = Poison.encode!(%{version: "2.0.0", dependencies: %{}})
      stub_read(:ok, "wand.json", json)
      assert WandFile.load() == {:error, :version_mismatch}
    end

    test ":invalid_dependencies when the key is not a map" do
      json = Poison.encode!(%{version: "1.0.0", dependencies: []})
      stub_read(:ok, "wand.json", json)
      assert WandFile.load() == {:error, :invalid_dependencies}
    end

    test ":invalid dependency when a dependency is invalid" do
      json = Poison.encode!(%{
        version: "1.0.0",
        dependencies: %{
          mox: "== == 1.0.0"
        }
      })
      stub_read(:ok, "wand.json", json)
      assert WandFile.load() == {:error, {:invalid_dependency, :mox}}
    end
  end

  defp stub_read_valid(path \\ "wand.json") do
    contents = valid_deps() |> Poison.encode!()
    stub_read(:ok, path, contents)
  end

  defp stub_not_found(), do: stub_read(:error, "wand.json", :enoent)

  defp stub_read(:ok, path, contents) do
    expect(Wand.FileMock, :read, fn ^path -> {:ok, contents} end)
  end

  defp stub_read(:error, path, error) do
    expect(Wand.FileMock, :read, fn ^path -> {:error, error} end)
  end

  defp valid_deps() do
    %{
      version: "1.0.0",
      dependencies: %{
        mox: ["~> 0.3.2", %{only: "test"}],
        poison: "~> 3.1",
      }
    }
  end

  defp valid_deps_config() do
    %WandFile{
      version: "1.0.0",
      dependencies: [
        %WandFile.Dependency{
          name: :mox,
          requirement: "~> 0.3.2",
          opts: %{only: "test"}
        },
        %WandFile.Dependency{
          name: :poison,
          requirement: "~> 3.1",
        }
      ]
    }
  end
end
