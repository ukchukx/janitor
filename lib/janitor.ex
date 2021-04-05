defmodule Janitor do
  @moduledoc false

  require Logger
  alias Janitor.Core.{BackupSchedule, BackupScheduleValidator}
  alias Janitor.Boundary.BackupScheduleManager

  def persistence_module, do: Application.get_env(:janitor, :persistence_module)

  def start do
    persistence_module().all_backup_schedules()
    |> Enum.map(fn map = %{name: name} ->
      opts = Keyword.new(map)
      BackupSchedule.new(name, map.db, map.username, opts)
    end)
    |> Enum.each(&start_schedule/1)

    num_schedules = BackupScheduleManager.active_schedules() |> length
    Logger.info("Loaded #{num_schedules} schedule(s)")
  end

  def stop,
    do: BackupScheduleManager.active_schedules() |> Enum.each(&BackupScheduleManager.stop/1)

  def start_schedule(schedule = %BackupSchedule{id: id}) when not is_nil(id) do
    BackupScheduleManager.start(schedule)
  end

  def stop_schedule(schedule = %BackupSchedule{id: id}) when not is_nil(id) do
    BackupScheduleManager.stop(schedule)
  end

  def delete_backup_schedule(id) do
    id
    |> BackupScheduleManager.flush_backups()
    |> case do
      schedule = %BackupSchedule{} -> BackupScheduleManager.stop(schedule)
      x -> x
    end

    persistence_module().delete_backup_schedule(id)
  end

  def create_backup_schedule(attrs, start_process \\ false) when is_map(attrs) do
    case BackupScheduleValidator.errors(attrs) do
      :ok ->
        backup_schedule =
          BackupSchedule.new(attrs.name, attrs.db, attrs.username, Keyword.new(attrs))

        persistence_module().save_backup_schedule(backup_schedule)

        if start_process do
          start_schedule(backup_schedule)
        end

        {:ok, backup_schedule}

      errors ->
        {:error, errors}
    end
  end

  def update_backup_schedule(id, attrs) when is_map(attrs) do
    with schedule = %{} <- BackupScheduleManager.state(id),
         :ok <- BackupScheduleValidator.errors(attrs) do
      schedule =
        attrs
        |> Map.keys()
        |> Enum.filter(&(&1 != :backups))
        |> Enum.reduce(schedule, fn field, schedule ->
          %{schedule | field => attrs[field]}
        end)

      persistence_module().save_backup_schedule(schedule)
      {:ok, BackupScheduleManager.update_backup_schedule(schedule)}
    else
      errors -> {:error, errors}
      :not_running -> {:error, :not_found}
    end
  end

  def get_backup_schedule(id) do
    case BackupScheduleManager.state(id) do
      schedule = %{} -> {:ok, schedule}
      :not_running -> {:error, :not_found}
    end
  end

  def all_backup_schedules do
    BackupScheduleManager.active_schedules()
    |> Enum.map(&BackupScheduleManager.state/1)
  end

  def run_backup(id), do: BackupScheduleManager.run_backup(id)

  def delete_backup(id, file_name), do: BackupScheduleManager.delete_backup(id, file_name)

  if Application.get_env(:janitor, :env) == :test do
    def clear_backups_from_db, do: persistence_module().clear_backups()
  end
end
