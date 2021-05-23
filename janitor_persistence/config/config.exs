use Mix.Config

config :janitor_persistence,
  db_dir: "./priv/db"

import_config "#{Mix.env()}.exs"
