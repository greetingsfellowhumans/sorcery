defmodule Sorcery.MixProject do
  use Mix.Project

  def project do
    [
      app: :sorcery,
      name: "Sorcery",
      version: "0.2.3",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: ["test.watch": :test],
      source_url: "https://github.com/greetingsfellowhumans/sorcery",
      package: package(),
      deps: deps()
    ]
  end

  defp package do
    [
      name: "sorcery",
      description: "Share some data in your assigns between multiple LiveView processes.",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/greetingsfellowhumans/sorcery"},
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:norm, "~> 0.13"},
      {:jason, "~> 1.2"},
      {:stream_data, "~> 0.4"},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:ecto, "~> 3.7.2", only: [:dev, :test], runtime: false},
    ]
  end
end
