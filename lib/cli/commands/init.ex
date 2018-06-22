defmodule Wand.CLI.Commands.Init do
  @behaviour Wand.CLI.Command

  def help(_type) do
  end

  def validate(args) do
    flags = [
      overwrite: :boolean,
      task_only: :boolean,
      force: :boolean
    ]

    {switches, [_ | commands], errors} = OptionParser.parse(args, strict: flags)

    case Wand.CLI.Command.parse_errors(errors) do
      :ok -> get_path(commands, switches)
      error -> error
    end
  end

  defp get_path([], switches), do: {:ok, {"./", switches}}
  defp get_path([path], switches), do: {:ok, {path, switches}}
  defp get_path(_, _), do: {:error, :wrong_command}
end
