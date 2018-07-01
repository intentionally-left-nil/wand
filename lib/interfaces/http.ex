defmodule Wand.Interfaces.Http do
  @moduledoc false
  alias HTTPoison.Response
  alias HTTPoison.Error
  @type headers :: [{atom, binary}]
  @callback get(uri :: binary(), headers) :: {:ok, Response.t()} | {:error, Error.t()}

  def impl() do
    Application.get_env(:wand, :http, HTTPoison)
  end
end
