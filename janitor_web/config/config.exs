# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :janitor_web, JanitorWeb.Endpoint,
  url: [host: {:system, "JANITOR_DNS_HOST"}],
  http: [
    port: {:system, :integer, "JANITOR_PORT", 4000},
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: {:system, "JANITOR_SECRET_KEY_BASE"},
  render_errors: [view: JanitorWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: JanitorWeb.PubSub,
  live_view: [signing_salt: "+tWb8+Kq"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger,
  utc_log: true,
  truncate: :infinity

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :janitor,
  bucket_store: Janitor.Boundary.B2Bucket,
  bucket_id: {:system, "JANITOR_BUCKET_ID"},
  bucket_name: {:system, "JANITOR_BUCKET_NAME"},
  bucket_access_key: {:system, "JANITOR_BUCKET_ACCESS_KEY"},
  bucket_access_key_id: {:system, "JANITOR_BUCKET_ACCESS_KEY_ID"},
  superuser_password: {:system, "JANITOR_SUPERUSER_PASSWORD"},
  schedule_supervisor: Janitor.Supervisor.BackupScheduleManager,
  schedule_registry: Janitor.Registry.BackupScheduleManager,
  persistence_module: JanitorPersistence,
  ecto_repos: [JanitorPersistence.Repo]

config :janitor_persistence,
  ecto_repos: [JanitorPersistence.Repo]

config :janitor_persistence, JanitorPersistence.Repo,
  database: "priv/db/janitor.sqlite3"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
