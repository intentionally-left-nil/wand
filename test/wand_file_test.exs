defmodule WandFileTest do
  use ExUnit.Case
  import Mox
  alias Wand.WandFile

  describe "load" do
    test "loads the default wand.json file" do
      stub_read_valid()
      assert WandFile.load() == {:ok, valid_deps()}
    end

    test "loads a given path" do
      stub_read_valid("/path/to/wand.json")
      assert WandFile.load("/path/to/wand.json") == {:ok, valid_deps()}
    end

    test "returns an error if not found" do
      stub_not_found()
      assert WandFile.load() == {:error, :enoent}
    end

    test "returns an error if not valid JSON" do
      stub_read(:ok, "wand.json", "[ NOT VALID JSON")
      assert WandFile.load() == {:error, {:invalid, "N", 2}}
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
      "version" => "1.0",
      "dependencies" => %{
        "mox" => ["~> 0.3.2", %{"only" => "test"}],
        "poison" => "~> 3.1",
      }
    }
  end
end
