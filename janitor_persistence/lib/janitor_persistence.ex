defmodule JanitorPersistence do
  @moduledoc false
  alias JanitorPersistence.Repo
  alias JanitorPersistence.Schema.BackupSchedule

  require Logger

  def save_backup_schedule(backup_schedule), do: save(BackupSchedule, backup_schedule)

  def all_backup_schedules, do: BackupSchedule |> Repo.all |> Enum.map(&BackupSchedule.to_map/1)

  def clear_backups do
    Repo.delete_all(BackupSchedule)
    :ok
  end

  def delete_backup_schedule(schedule_id) do
    BackupSchedule
    |> Repo.get(schedule_id)
    |> case do
      nil ->
        :ok

      schedule ->
        Repo.delete(schedule)
        :ok
    end
  end

  defp save(schema, %{id: id} = model) do
    schema
    |> Repo.get(id)
    |> case do
      nil ->
        model
        |> schema.from_model
        |> schema.changeset
        |> Repo.insert

      record ->
        record
        |> schema.changeset(schema.from_model(model))
        |> Repo.update()
    end
    |> case do
      {:ok, record} ->
        {:ok, schema.to_map(record)}
      {:error, ch} ->
        Logger.error("Could not save #{inspect(schema)} (#{id}) due to #{inspect(ch)}")
        {:error, :could_not_save}
    end
  end
end
