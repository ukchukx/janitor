use Mix.Config

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
  b2_auth_url: "https://api.backblazeb2.com/b2api/v2/b2_authorize_account",
  ecto_repos: [JanitorPersistence.Repo]

config :ex_aws,
  debug_requests: true,
  json_codec: Jason,
  access_key_id: {:system, "JANITOR_BUCKET_ACCESS_KEY_ID"},
  secret_access_key: {:system, "JANITOR_BUCKET_ACCESS_KEY"},
  region: "us-west-000"

config :ex_aws, :s3,
  scheme: "https://",
  host: "s3.us-west-000.backblazeb2.com",
  region: "us-west-000"

config :logger, level: :info

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: []

import_config "../janitor_persistence/config/config.exs"
import_config "#{Mix.env()}.exs"
