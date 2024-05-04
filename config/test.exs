import Config


config :sorcery, Sorcery.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "sorcery_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :sorcery,
  ecto_repos: [Sorcery.Repo]

config :logger,
  level: :warning
