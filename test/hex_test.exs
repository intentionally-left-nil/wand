defmodule HexTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.Hex
  alias HTTPoison.{Response, Error}

  setup :verify_on_exit!

  test "releases returns :not_found if the package isn't on hex" do
    stub_http(:ok, 404, "")
    assert Hex.releases("not_a_module") == {:error, :not_found}
  end

  test "returns :not_found if there are no releases" do
    stub_http(:ok, 200, %{releases: []})
    assert Hex.releases("poison") == {:error, :not_found}
  end

  test "releases returns :no_connection if HTTPoison returns an error" do
    stub_http(:error)
    assert Hex.releases("poison") == {:error, :no_connection}
  end

  test "returns :bad_response when the server returns non-json" do
    stub_http(:ok, 200, "[NOT JSON")
    assert Hex.releases("poison") == {:error, :bad_response}
  end

  test "returns :bad_response when the server returns a 400" do
    stub_http(:ok, 400, "")
    assert Hex.releases("poison") == {:error, :bad_response}
  end

  test "returns :bad_response when missing the releases key" do
    stub_http(:ok, 200, "{}")
    assert Hex.releases("poison") == {:error, :bad_response}
  end

  test "returns the releases" do
    stub_http(:ok, 200, valid_body())

    expected =
      {:ok,
       [
         "3.1.0",
         "3.0.0",
         "2.2.0",
         "2.1.0",
         "2.0.1",
         "2.0.0",
         "1.5.2",
         "1.5.1",
         "1.5.0",
         "1.4.0",
         "1.3.1",
         "1.3.0",
         "1.2.1",
         "1.2.0",
         "1.1.1",
         "1.1.0",
         "1.0.3",
         "1.0.2",
         "1.0.1",
         "1.0.0"
       ]}

    assert Hex.releases("poison") == expected
  end

  test "strips out invalid releases" do
    stub_http(:ok, 200, %{
      releases: [
        %{version: "1.1.0"},
        %{missing_version: "1.1.0"},
        %{version: "ABC"}
      ]
    })

    assert Hex.releases("poison") == {:ok, ["1.1.0"]}
  end

  defp stub_http(:ok, status, %{} = contents),
    do: stub_http(:ok, status, WandCore.Poison.encode!(contents))

  defp stub_http(:ok, status, contents) do
    response = %Response{
      status_code: status,
      body: contents
    }

    expect(Wand.HttpMock, :get, fn _url, _headers -> {:ok, response} end)
  end

  defp stub_http(:error) do
    response = %Error{id: nil, reason: :nxdomain}
    expect(Wand.HttpMock, :get, fn _url, _headers -> {:error, response} end)
  end

  defp valid_body() do
    "{\"docs_html_url\":\"https://hexdocs.pm/poison/\",\"downloads\":{\"all\":6270192,\"day\":13995,\"recent\":962319,\"week\":81020},\"html_url\":\"https://hex.pm/packages/poison\",\"inserted_at\":\"2014-08-20T04:43:51.000000\",\"meta\":{\"description\":\"An incredibly fast, pure Elixir JSON library\",\"licenses\":[\"CC0-1.0\"],\"links\":{\"GitHub\":\"https://github.com/devinus/poison\"},\"maintainers\":[\"Devin Torres\"]},\"name\":\"poison\",\"owners\":[{\"email\":\"devin@devintorr.es\",\"url\":\"https://hex.pm/api/users/devinus\",\"username\":\"devinus\"}],\"releases\":[{\"url\":\"https://hex.pm/api/packages/poison/releases/3.1.0\",\"version\":\"3.1.0\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/3.0.0\",\"version\":\"3.0.0\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/2.2.0\",\"version\":\"2.2.0\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/2.1.0\",\"version\":\"2.1.0\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/2.0.1\",\"version\":\"2.0.1\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/2.0.0\",\"version\":\"2.0.0\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/1.5.2\",\"version\":\"1.5.2\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/1.5.1\",\"version\":\"1.5.1\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/1.5.0\",\"version\":\"1.5.0\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/1.4.0\",\"version\":\"1.4.0\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/1.3.1\",\"version\":\"1.3.1\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/1.3.0\",\"version\":\"1.3.0\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/1.2.1\",\"version\":\"1.2.1\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/1.2.0\",\"version\":\"1.2.0\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/1.1.1\",\"version\":\"1.1.1\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/1.1.0\",\"version\":\"1.1.0\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/1.0.3\",\"version\":\"1.0.3\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/1.0.2\",\"version\":\"1.0.2\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/1.0.1\",\"version\":\"1.0.1\"},{\"url\":\"https://hex.pm/api/packages/poison/releases/1.0.0\",\"version\":\"1.0.0\"}],\"repository\":\"hexpm\",\"retirements\":{},\"updated_at\":\"2017-01-15T01:34:31.327060\",\"url\":\"https://hex.pm/api/packages/poison\"}"
  end
end
