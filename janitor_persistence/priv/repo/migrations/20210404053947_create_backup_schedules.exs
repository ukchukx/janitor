defmodule JanitorPersistence.Repo.Migrations.CreateBackupSchedules do
  use Ecto.Migration

  def change do
    create table(:backup_schedules, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :db, :string
      add :username, :string
      add :password, :string
      add :host, :string
      add :port, :integer
      add :frequency, :string
      add :preserve, :integer
      add :days, :string
      add :times, :string
      timestamps(type: :utc_datetime)
    end
    create index(:backup_schedules, [:db])
  end
end
