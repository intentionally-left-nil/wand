defmodule Wand.MixProject do
  use Mix.Project

  @version "0.2.0"
  @description "A CLI tool to manage package dependencies"
  @cli_env [
    coveralls: :test,
    "coveralls.detail": :test,
    "coveralls.post": :test,
    "coveralls.html": :test
  ]

  def project do
    [
      aliases: aliases(),
      app: :wand,
      deps: deps(),
      description: @description,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      escript: [main_module: Wand.CLI],
      package: package(),
      preferred_cli_env: @cli_env,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      version: @version
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      build: [&build_cli/1]
    ]
  end

  defp build_cli(_) do
    Mix.Tasks.Compile.run([])
    Mix.Tasks.Escript.Build.run([])
  end

  defp deps do
    [
      {:earmark, "~> 1.2"},
      {:httpoison, "~> 1.2"},
      {:wand_core, "~> 0.3"},
      {:excoveralls, "~> 0.9.1", only: :test},
      {:mox, "~> 0.3.2", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:junit_formatter, "~> 2.2", only: [:test]}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      name: :wand,
      files: ["lib", "mix.exs"],
      docs: [extras: ["README.md"]],
      maintainers: ["Anil Kulkarni"],
      licenses: ["BSD-3"],
      links: %{"Github" => "https://github.com/AnilRedshift/wand"}
    ]
  end
end
