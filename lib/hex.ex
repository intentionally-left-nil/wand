defmodule Wand.Hex do
  @moduledoc false
  alias HTTPoison.{Error, Response}
  @http Wand.Interfaces.Http.impl()
  @base "https://hex.pm/"
  @headers [{"Accept", "application/json"}]

  def releases(package) do
    URI.parse(@base)
    |> URI.merge("/api/packages/#{URI.encode(package)}")
    |> @http.get(@headers)
    |> parse_response
  end

  defp parse_response({:ok, %Response{status_code: 200, body: body}}) do
    WandCore.Poison.decode(body)
    |> parse_json
  end

  defp parse_response({:ok, %Response{status_code: 404}}) do
    {:error, :not_found}
  end

  defp parse_response({:ok, %Response{}}), do: {:error, :bad_response}
  defp parse_response({:error, %Error{}}), do: {:error, :no_connection}

  defp parse_json({:ok, %{"releases" => releases}}) do
    releases =
      Enum.map(releases, &Map.get(&1, "version"))
      |> Enum.reject(&(&1 == nil or Version.parse(&1) == :error))

    case releases do
      [] -> {:error, :not_found}
      releases -> {:ok, releases}
    end
  end

  defp parse_json(_), do: {:error, :bad_response}
end
