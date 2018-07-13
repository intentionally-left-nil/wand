defmodule Wand.Test.IntegrationRunner do
  use Modglobal

  def init() do
    {:ok, pid} = Agent.start_link(fn -> nil end)
    set_global(:binary, pid)

    {:ok, pid} = Agent.start_link(fn -> nil end)
    set_global(:archive, pid)
  end

  def ensure_binary() do
    get_global(:binary)
    |> Agent.get_and_update(fn
      nil ->
        state = compile_binary()
        {state, state}

      state ->
        {state, state}
    end)
  end

  def ensure_archive() do
    get_global(:archive)
    |> Agent.get_and_update(fn
      nil ->
        state = compile_archive()
        {state, state}

      state ->
        {state, state}
    end)
  end

  def wand(command) do
    path =
      case File.exists?("./wand") do
        true -> Path.expand("./wand")
        false -> Path.expand("../../wand")
      end

    execute(path <> " " <> command, print?())
  end

  def execute(command, print \\ false) do
    [command | args] = OptionParser.split(command)
    {message, status} = System.cmd(command, args, stderr_to_stdout: true)

    if print do
      """
      ****
      wand #{command}
      ****

      #{message}
      ------------------------------------
      """
      |> IO.puts()
    end

    case status do
      0 ->
        :ok

      _ ->
        {:error, status}
    end
  end

  def in_dir(fun) do
    folder = create_folder()

    try do
      File.cd!(folder, fun)
    after
      File.rm_rf!(folder)
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

    {_message, status} =
      System.cmd("mix", ["build"], stderr_to_stdout: true, env: [{"MIX_ENV", "prod"}])

    case status do
      0 ->
        IO.puts("Finished compiling wand binary")

      _ ->
        :error
    end
  end

  defp compile_archive() do
    IO.puts("Installing wand.core from hex.pm")

    {_message, status} =
      System.cmd(
        "mix",
        ["archive.install", "hex", "wand_core", "--force"],
        stderr_to_stdout: true,
        env: [{"MIX_ENV", "prod"}]
      )

    case status do
      0 ->
        IO.puts("Finished installing archive")

      _ ->
        :error
    end
  end

  defp create_folder() do
    folder = Path.join("./tmp", "test_#{increment_global(:folder)}")
    File.mkdir_p!(folder) && folder
  end
end
