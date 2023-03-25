import Config

config :janitor_persistence,
  ecto_repos: [JanitorPersistence.Repo]

config :janitor_persistence, JanitorPersistence.Repo,
  username: {:system, "JANITOR_DB_USER"},
  password: {:system, "JANITOR_DB_PASS"},
  database: {:system, "JANITOR_DB_NAME"},
  hostname: {:system, "JANITOR_DB_HOST"},
  pool_size: {:system, :integer, "JANITOR_DB_POOL_SIZE", 10},
  charset: "utf8mb4",
  collation: "utf8mb4_unicode_ci",
  telemetry_prefix: [:janitor, :repo]

import_config "#{Mix.env()}.exs"
