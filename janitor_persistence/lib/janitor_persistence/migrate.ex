defmodule JanitorPersistence.Migrate do
  @moduledoc false

  require Logger

  def run do
    Logger.info("Running migrations...")
    path = Application.app_dir(:janitor_persistence, "priv/repo/migrations")
    Ecto.Migrator.run(JanitorPersistence.Repo, path, :up, all: true)
    Logger.info("Done running migrations")
  end
end
