defmodule Wand.Test.IntegrationRunner do
  use Modglobal

  def ensure_binary() do
    get_agent(:binary)
    |> Agent.get_and_update(fn
      nil ->
        state = compile_binary()
        {state, state}
      state -> {state, state}
    end)
  end

  def ensure_archive() do
    get_agent(:archive)
    |> Agent.get_and_update(fn
      nil ->
        state = compile_archive()
        {state, state}
      state -> {state, state}
    end)
  end

  def wand(command) do
    {message, status} = Path.expand("./wand")
    |> System.cmd(OptionParser.split(command), stderr_to_stdout: true)

    if print?() do
      """
      ****
      wand #{command}
      ****

      #{message}
      ------------------------------------
      """ |> IO.puts()
    end

    case status do
      0 -> :ok
      _ -> {:error, status}
    end
  end

  defp print?() do
    OptionParser.parse(System.argv(), switches: [include: :keep])
    |> elem(0)
    |> Enum.find(&(&1 == {:include, "print"}))
    |> case do
      nil -> false
      _ -> true
    end
  end

  defp compile_binary() do
    IO.puts("Compiling wand binary")
    {_message, status} = System.cmd("mix", ["build"], stderr_to_stdout: true)
    case status do
      0 ->
        IO.puts("Finished compiling wand binary")
      _ -> :error
    end
  end

  defp compile_archive() do
    IO.puts("Installing wand.core from hex.pm")
    {_message, status} = System.cmd("mix", ["archive.install", "hex", "wand_core", "--force"], stderr_to_stdout: true)
    case status do
      0 ->
        IO.puts("Finished installing archive")
      _ -> :error
    end
  end

  defp get_agent(name) do
    if get_global(name) == nil do
      {:ok, pid} = Agent.start_link(fn -> nil end)
      # Worst case we create a bunch of empty agents
      # in between this race condition. However, it's not worth solving that
      # for tests cases. Importantly, only one compile_binary() will be called.
      set_global(name, pid)
    end
    get_global(name)
  end
end
