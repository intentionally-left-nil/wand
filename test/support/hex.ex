defmodule Wand.Test.Helpers.Hex do
  import Mox
  alias HTTPoison.{Response, Error}

  def stub_poison() do
    url = "https://hex.pm/api/packages/poison"
    releases = [
      "3.1.0", "3.0.0", "2.2.0", "2.1.0", "2.0.1", "2.0.0", "1.5.2",
      "1.5.1", "1.5.0", "1.4.0", "1.3.1", "1.3.0", "1.2.1", "1.2.0",
      "1.1.1", "1.1.0", "1.0.3", "1.0.2", "1.0.1", "1.0.0"
    ]
    |> Enum.map(&(%{version: &1}))

    body =  %{releases: releases} |> Poison.encode!()

    response = %Response{
      body: body,
      status_code: 200,
    }
    expect(Wand.HttpMock, :get, fn(_url, _headers) -> {:ok, response} end)
  end
end
