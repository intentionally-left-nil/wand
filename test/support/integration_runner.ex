defmodule Wand.Test.IntegrationRunner do
  use Modglobal

  def ensure_binary() do
    get_agent()
    |> Agent.get_and_update(fn
      nil ->
        state = compile_binary()
        {state, state}
      state -> {state, state}
    end)
  end


  defp compile_binary() do
    IO.puts("Compiling wand binary")
    {message, status} = System.cmd("mix", ["build"], stderr_to_stdout: true)
    case status do
      0 ->
        IO.puts("Finished compiling wand binary")
      _ -> :error
    end
  end

  defp get_agent() do
    if get_global(:agent) == nil do
      {:ok, pid} = Agent.start_link(fn -> nil end)
      # Worst case we create a bunch of empty agents
      # in between this race condition. However, it's not worth solving that
      # for tests cases. Importantly, only one compile_binary() will be called.
      set_global(:agent, pid)
    end
    get_global(:agent)
  end
end
