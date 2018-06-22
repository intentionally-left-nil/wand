defmodule Wand.CLI.Command do
  @callback validate(args :: list) :: {:ok, any()} | {:error, any()}
end
