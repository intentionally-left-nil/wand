defmodule Wand.Test.Helpers.Hex do
  import Mox
  alias HTTPoison.Response

  def stub_poison() do
    releases = [
      "3.1.0", "3.0.0", "2.2.0", "2.1.0", "2.0.1", "2.0.0", "1.5.2",
      "1.5.1", "1.5.0", "1.4.0", "1.3.1", "1.3.0", "1.2.1", "1.2.0",
      "1.1.1", "1.1.0", "1.0.3", "1.0.2", "1.0.1", "1.0.0"
    ]
    |> Enum.map(&(%{version: &1}))

    body =  %{releases: releases} |> Poison.encode!()

    %Response{
      body: body,
      status_code: 200,
    }
    |> stub_ok()
  end

  def stub_not_found() do
    %Response{
      body: "",
      status_code: 404,
    }
    |> stub_ok()
  end

  defp stub_ok(response) do
    uri = URI.parse("https://hex.pm/api/packages/poison")
    expect(Wand.HttpMock, :get, fn(^uri, _headers) -> {:ok, response} end)
  end
end
