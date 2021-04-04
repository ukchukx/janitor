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

  def create_backup_schedule(attrs) when is_map(attrs) do
    case BackupScheduleValidator.errors(attrs) do
      :ok ->
        backup_schedule =
          BackupSchedule.new(attrs.name, attrs.db, attrs.username, Keyword.new(attrs))

        persistence_module().save_backup_schedule(backup_schedule)
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
        |> Enum.reduce(schedule, fn field, schedule -> %{schedule | field => attrs[field]} end)

      persistence_module().save_backup_schedule(schedule)
      BackupScheduleManager.update_backup_schedule(schedule)
      {:ok, schedule}
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
end
