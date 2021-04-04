defmodule JanitorPersistence do
  @moduledoc false
  alias JanitorPersistence.Repo
  alias JanitorPersistence.Schema.BackupSchedule

  require Logger

  def save_backup_schedule(backup_schedule), do: save(BackupSchedule, backup_schedule)

  def all_backup_schedules do
    BackupSchedule
    |> Repo.all
    |> Enum.map(&BackupSchedule.to_map/1)
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
