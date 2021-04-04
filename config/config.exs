use Mix.Config

config :janitor,
  bucket_id: {:system, "JANITOR_BUCKET_ID"},
  bucket_name: {:system, "JANITOR_BUCKET_NAME"},
  bucket_access_key: {:system, "JANITOR_BUCKET_ACCESS_KEY"},
  bucket_access_key_id: {:system, "JANITOR_BUCKET_ACCESS_KEY_ID"},
  superuser_password: {:system, "JANITOR_SUPERUSER_PASSWORD"},
  schedule_supervisor: Janitor.Supervisor.BackupScheduleManager,
  schedule_registry: Janitor.Registry.BackupScheduleManager,
  persistence_module: JanitorPersistence,
  ecto_repos: [JanitorPersistence.Repo]

config :logger, level: :info

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: []

config :janitor_persistence,
  ecto_repos: [JanitorPersistence.Repo]

config :janitor_persistence, JanitorPersistence.Repo, database: "priv/db/janitor.sqlite3"

import_config "#{Mix.env()}.exs"
