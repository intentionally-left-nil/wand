defmodule Wand.Interfaces.System do
  @moduledoc false
  @callback halt(status :: integer()) :: no_return()
  @callback cmd(binary(), [binary()], keyword()) ::
              {Collectable.t(), exit_status :: non_neg_integer()}

  def impl() do
    Application.get_env(:wand, :system, System)
  end
end
