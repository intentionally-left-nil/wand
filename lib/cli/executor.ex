defmodule Wand.CLI.Executor do
  alias Wand.CLI.WandFileWithHelp
  alias Wand.CLI.CoreValidator
  alias WandCore.WandFile

  def run(module, data) do
    options = get_options(module)
    with :ok <- ensure_core(options),
    {:ok, file} <- ensure_wand_file_loaded(options),
    extras <- get_extras(file),
    :ok <- execute(module, data, extras)
    do
      :ok
    else
      {:error, :require_core, reason} ->
        CoreValidator.handle_error(reason)

      {:error, :wand_file, reason} ->
        WandFileWithHelp.handle_error(reason)

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

  defp get_extras(file) do
    [
      wand_file: file
    ]
    |> Enum.reject(&(&1 |> elem(1) == nil))
    |> Enum.into(%{})
  end

  defp execute(module, data, extras) do
    case module.execute(data, extras) do
      :ok -> :ok
      {:ok, %WandFile{}=file} -> save_file_with_callbacks(module, file)
      error -> error
    end
  end

  defp save_file_with_callbacks(module, file) do
    case WandFileWithHelp.save(file) do
      :ok -> after_save(module)
      error -> error
    end
  end

  defp after_save(module) do
    if function_exported?(module, :after_save, 0) do
      module.after_save()
    else
      :ok
    end
  end

  defp ensure_core(options) do
    case options[:require_core] do
      true -> CoreValidator.require_core()
      _ -> :ok
    end
  end

  defp ensure_wand_file_loaded(options) do
    case options[:load_wand_file] do
      true -> WandFileWithHelp.load()
      _ -> {:ok, nil}
    end
  end
end
