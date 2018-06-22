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
      version: @version,
      description: @description,
      elixir: "~> 1.6",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: @cli_env,
      escript: [main_module: Wand.CLI],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
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
    File.rename("wand", "../wand-archive/cli/wand")
    File.cp("../wand-archive/cli/wand", "../wand-archive/cli/wand-#{@version}")
  end

  defp deps do
    [
      {:excoveralls, "~> 0.9.1", only: :test},
      {:mox, "~> 0.3.2", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:junit_formatter, "~> 2.2", only: [:test]}
    ]
  end

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
