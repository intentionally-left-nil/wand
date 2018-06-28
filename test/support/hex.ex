defmodule Wand.Test.Helpers.Hex do
  import Mox
  alias HTTPoison.{Error, Response}

  def stub_poison() do
    releases =
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
      ]
      |> Enum.map(&%{version: &1})

    body = %{releases: releases} |> Poison.encode!()

    %Response{
      body: body,
      status_code: 200
    }
    |> stub_http()
  end

  def stub_not_found() do
    %Response{
      body: "",
      status_code: 404
    }
    |> stub_http()
  end

  def stub_no_connection() do
    %Error{id: nil, reason: :nxdomain}
    |> stub_http(:error)
  end

  def stub_bad_response() do
    %Response{
      body: "[NOT JSON",
      status_code: 200
    }
    |> stub_http()
  end

  defp stub_http(response, type \\ :ok) do
    uri = URI.parse("https://hex.pm/api/packages/poison")
    expect(Wand.HttpMock, :get, fn ^uri, _headers -> {type, response} end)
  end
end
