defmodule Janitor.Core.BackupStore do
  @moduledoc false
  alias Janitor.Core.Backup
  @callback all_backups :: [Backup.t()]
  @callback backups_for_schedule(name :: binary) :: [Backup.t()]
  @callback clear_backups_for_schedule(name :: binary) :: :ok
  @callback clear_orphaned_backups_for_schedule(name :: binary) :: :ok
  @callback delete_backups(backups :: [Backup.t()]) :: :ok
  @callback upload_backup(path :: binary, file_name :: binary) :: {:ok, Backup.t()} | {:error, atom}
end
