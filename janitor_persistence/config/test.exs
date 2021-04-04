use Mix.Config

config :janitor_persistence, env: :test

config :janitor_persistence, JanitorPersistence.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "priv/db/janitor_test.sqlite3"
