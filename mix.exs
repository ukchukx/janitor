defmodule Janitor.MixProject do
  use Mix.Project

  def project do
    [
      app: :janitor,
      version: "1.0.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Janitor.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:confex, "~> 3.4.0"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:elixir_uuid, "~> 1.2"},
      {:ex_aws, git: "https://github.com/ukchukx/ex_aws.git", ref: "b4382e6", override: true},
      {:ex_aws_s3,
       git: "https://github.com/ukchukx/ex_aws_s3.git", ref: "a2651c2", override: true},
      {:finch, "~> 0.4"},
      {:hackney, "~> 1.16"},
      {:janitor_persistence, path: "./janitor_persistence"},
      {:jason, "~> 1.2"},
      {:sweet_xml, "~> 0.6"}
    ]
  end

  defp aliases do
    [
      test: ["ecto.drop --quiet", "ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
