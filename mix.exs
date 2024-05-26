defmodule Sorcery.MixProject do
  use Mix.Project

  def project do
    [
      app: :sorcery,
      version: "0.3.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      docs: [
        main: "Sorcery", # The main page in the docs
        extras: extras(),
        #logo: "path/to/logo.png",
        extra_section: "GUIDES",
        groups_for_extras: groups_for_extras(),
        skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
        extras: extras()
      ],
      elixirc_paths: elixirc_paths(Mix.env),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]

  defp extras() do
      ["CHANGELOG.md"] ++ Path.wildcard("guides/*/*.md") ++ Path.wildcard("guides/*/*.cheatmd")
  end
  defp groups_for_extras do
    [
      "Schemas": ~r/guides\/schemas\/.?/,
      "Queries": ~r/guides\/queries\/.?/,
      "Mutations": ~r/guides\/mutations\/.?/,
      "Portals": ~r/guides\/portals\/.?/,

      #"Server-side features": ~r/guides\/server\/.?/,
      #"Client-side integration": ~r/guides\/client\/.?/
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
      {:stream_data, "~> 0.6.0"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:ecto, "~> 3.11.2"},
      {:ecto_sql, "~> 3.11.1"},
      {:postgrex, ">= 0.0.0"},
      {:explorer, "~> 0.8.0"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
    ]
  end
end
