defmodule Wand.CLI.Executor do
  def run(module, data) do
    options = get_options(module)
    with :ok <- ensure_core(options)
    do
      module.execute(data)
    else
      {:error, :require_core, reason} ->
        Wand.CLI.CoreValidator.handle_error(reason)

      error -> error
    end
  end

  defp get_options(module) do
    if function_exported?(module, :options, 0) do
      module.options()
    else
      []
    end
  end

  defp ensure_core(options) do
    case options[:require_core] do
      true -> Wand.CLI.CoreValidator.require_core()
      _ -> :ok
    end
  end
end
