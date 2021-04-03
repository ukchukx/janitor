defmodule Janitor do
  @moduledoc false

  require Logger
  alias Janitor.Core.BackupSchedule
  alias Janitor.Boundary.BackupScheduleManager

  def persistence_module, do: Application.get_env(:janitor, :persistence_module)

  def start do
    persistence_module().backup_schedules()
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
    schedule
  end
end
