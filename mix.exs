defmodule Exeration.MixProject do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :exeration,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_add_deps: :apps_direct, plt_add_apps: []],
      docs: docs()
    ]
  end

  def application do
    [
      mod: {Exeration, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "overview",
      extra_section: "GUIDES",
      assets: "guides/assets",
      formatters: ["html", "epub"],
      groups_for_modules: groups_for_modules(),
      extras: extras(),
      groups_for_extras: groups_for_extras()
    ]
  end

  defp groups_for_modules do
    [
      Validators: [
        Exeration.Validation,
        Exeration.Authorization
      ],
      Attributes: [
        Exeration.Operation.Argument,
        Exeration.Operation.Authorize
      ],
      Behaviours: [
        Exeration.Validator
      ]
    ]
  end

  defp extras do
    ["guides/overview.md", "guides/attributes/authorize.md", "guides/attributes/argument.md"]
  end

  defp groups_for_extras do
    [
      Introduction: ~r/guides\/overview\/.?/,
      Attributes: ~r/guides\/attributes\/[^\/]+\.md/
    ]
  end
end
