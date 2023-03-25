import Config

config :janitor_persistence, env: :test

config :janitor_persistence, JanitorPersistence.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: {:system, "JANITOR_DB_TEST_NAME"}
