use Mix.Config

config :janitor_persistence,
  ecto_repos: [JanitorPersistence.Repo]

config :janitor_persistence, JanitorPersistence.Repo,
  database: "priv/db/janitor.sqlite3"

import_config "#{Mix.env()}.exs"
