defmodule Flashy.MixProject do
  @moduledoc false

  use Mix.Project

  @app :flashy
  @name "Flashy"
  @description "Flashy is a small library that extends LiveView's flash support to function and live components"
  @version "0.3.0"
  @github "https://github.com/sezaru/#{@app}"
  @author "Eduardo Barreto Alexandre"
  @license "MIT"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.15",
      name: @name,
      description: @description,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env()
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:phoenix_live_view, "~> 1.0.12"},
      {:esbuild, "~> 0.9", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3.1", runtime: Mix.env() == :dev},
      {:typedstruct, "~> 0.5.3", runtime: false},
      {:phx_component_helpers, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @github,
      extras: [
        "README.md"
      ]
    ]
  end

  defp package do
    [
      name: @app,
      maintainers: [@author],
      licenses: [@license],
      links: %{"Github" => @github},
      files: ~w(mix.exs lib/flashy** package.json priv/static/flashy.min.js)
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build", "assets.package"],
      "assets.get": ["cmd --cd assets npm install"],
      "assets.setup": [
        "assets.get",
        "tailwind.install --if-missing",
        "esbuild.install --if-missing"
      ],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.package": ["esbuild package"],
      "assets.deploy": [
        "assets.get",
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  end
end
