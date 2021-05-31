use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :janitor_web, JanitorWeb.Endpoint,
  http: [port: 4002],
  server: false

config :janitor,
  bucket_store: Janitor.Boundary.TestBucket

config :janitor_persistence, JanitorPersistence.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: {:system, "JANITOR_DB_TEST_NAME"}

# Print only warnings and errors during test
config :logger, level: :warn
