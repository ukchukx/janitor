defmodule Janitor.Boundary.TestBucket do
  @moduledoc false
  alias Janitor.Core.{Backup, BackupStore, Utils}
  @behaviour BackupStore

  def all_backups, do: []

  def backups_for_schedule(_name), do: []

  def clear_backups_for_schedule(_name), do: :ok

  def delete_backups(_backups), do: :ok

  def upload_backup(_file_path, file_name),
    do: {:ok, %Backup{id: Utils.new_id(), name: file_name}}
end
