defmodule Wand.CLI.Mix do
  @system Wand.Interfaces.System.impl()

  def update_deps() do
    mix("deps.get", print_output: true)
  end

  def compile() do
    mix("compile", print_output: true)
  end

  defp mix(command, opts) do
    args = OptionParser.split(command)
    opts = case Keyword.get(opts, :print_output) do
      true -> [stderr_to_stdout: true, into: IO.stream(:stdio, :line)]
      false -> [stderr_to_stdout: true]
    end
    {message, code} = @system.cmd("mix", args, opts)

    case code do
      0 -> :ok
      code -> {:error, {code, message}}
    end
  end
end
