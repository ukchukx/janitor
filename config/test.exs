use Mix.Config

config :janitor, env: :test
config :logger, level: :warn

config :janitor,
  bucket_store: Janitor.Boundary.TestBucket

config :janitor_persistence, JanitorPersistence.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: {:system, "JANITOR_DB_TEST_NAME"}
