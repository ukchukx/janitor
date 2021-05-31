defmodule JanitorPersistence.SetupDatabase do
  @moduledoc false

  require Logger
  alias JanitorPersistence.Repo

  def create_database do
    Logger.info("Creating database...")

    case Repo.__adapter__().storage_up(Repo.config()) do
      :ok -> Logger.info("Database created")
      {:error, :already_up} -> Logger.info("Database already created")
      {:error, term} -> Logger.error("Database could not be created: #{inspect(term)}")
    end
  end

  def run_migrations do
    Logger.info("Running migrations...")
    path = Application.app_dir(:janitor_persistence, "priv/repo/migrations")
    Ecto.Migrator.run(JanitorPersistence.Repo, path, :up, all: true)
    Logger.info("Done running migrations")
  end
end
