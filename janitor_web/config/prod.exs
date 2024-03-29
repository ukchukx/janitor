import Config

config :janitor_web, JanitorWeb.Endpoint,
  server: true,
  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger,
  level: :info,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]
