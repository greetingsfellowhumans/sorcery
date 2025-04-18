defmodule Sorcery.MixProject do
  use Mix.Project

  def project do
    [
      app: :sorcery,
      version: "0.4.15",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      docs: [
        # main: "README.md", # The main page in the docs
        main: "readme",
        # extras: extras(),
        # logo: "path/to/logo.png",
        extra_section: "GUIDES",
        groups_for_extras: groups_for_extras(),
        skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
        extras: extras()
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      deps: deps()
    ]
  end

  defp package() do
    [
      name: "sorcery",
      description: "A framework which rethinks how data flows, and how we build apps.",
      licenses: ["MIT NO AI"],
      links: %{"GitHub" => "https://github.com/greetingsfellowhumans/sorcery"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]

  defp extras() do
    ["README.md", "CHANGELOG.md"] ++
      Path.wildcard("guides/*/*.md") ++ Path.wildcard("guides/*/*.cheatmd")
  end

  defp groups_for_extras do
    [
      Schemas: ~r/guides\/schemas\/.?/,
      Queries: ~r/guides\/queries\/.?/,
      Mutations: ~r/guides\/mutations\/.?/,
      Portals: ~r/guides\/portals\/.?/

      # "Server-side features": ~r/guides\/server\/.?/,
      # "Client-side integration": ~r/guides\/client\/.?/
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Sorcery.Application, []},
      extra_applications: [:logger, :mnesia]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mix_test_watch, "~> 1.2", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:stream_data, ">= 0.0.0"},
      {:ecto, ">= 3.0.0"},
      {:ecto_sql, ">= 3.0.0"},
      {:postgrex, ">= 0.0.0"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
    ]
  end
end
