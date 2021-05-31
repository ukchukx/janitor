defmodule Janitor.Boundary.BackupScheduleManager do
  @moduledoc false

  alias Janitor.Boundary.Utils
  alias Janitor.Core.BackupSchedule

  use GenServer
  require Logger

  def active_schedules do
    supervisor = Application.get_env(:janitor, :schedule_supervisor)
    registry = Application.get_env(:janitor, :schedule_registry)

    supervisor
    |> DynamicSupervisor.which_children()
    |> Enum.filter(&Utils.child_pid?(&1, __MODULE__))
    |> Enum.flat_map(&Utils.id_from_pid(&1, registry, __MODULE__))
  end

  def start(schedule = %BackupSchedule{}) do
    supervisor = Application.get_env(:janitor, :schedule_supervisor)
    DynamicSupervisor.start_child(supervisor, {__MODULE__, schedule})
    schedule
  end

  def running?(id) do
    active_schedules()
    |> Enum.any?(fn
      ^id -> true
      _ -> false
    end)
  end

  def stop(id) do
    case running?(id) do
      true -> id |> via |> GenServer.stop()
      false -> :not_running
    end
  end

  def state(id) do
    case running?(id) do
      true -> id |> via |> GenServer.call(:state)
      false -> :not_running
    end
  end

  def flush_backups(id) do
    case running?(id) do
      true -> id |> via |> GenServer.call(:flush_backups, 60_000)
      false -> :not_running
    end
  end

  def run_backup(id) do
    case running?(id) do
      true -> id |> via |> GenServer.call(:run_backup, 60_000)
      false -> :not_running
    end
  end

  def delete_backup(id, file_name) do
    case running?(id) do
      true -> id |> via |> GenServer.call({:delete_backup, file_name}, 30_000)
      false -> :not_running
    end
  end

  def update_backup_schedule(schedule = %BackupSchedule{id: id}) do
    case running?(id) do
      true -> id |> via |> GenServer.call({:update_fields, schedule}, 20_000)
      false -> :not_running
    end
  end

  #
  # Callbacks
  #

  def via(id) do
    {:via, Registry, {Application.get_env(:janitor, :schedule_registry), id}}
  end

  def child_spec(schedule = %BackupSchedule{id: id}) do
    %{
      id: {__MODULE__, id},
      start: {__MODULE__, :start_link, [schedule]},
      restart: :transient
    }
  end

  def start_link(schedule = %BackupSchedule{id: id}) do
    GenServer.start_link(__MODULE__, schedule, name: via(id), hibernate_after: 5_000)
  end

  def init(schedule = %BackupSchedule{}) do
    schedule_next_tick()
    {:ok, schedule, {:continue, :fetch_backups}}
  end

  def init(_), do: {:error, "Only backup schedules accepted"}

  def handle_continue(:fetch_backups, schedule) do
    Logger.info("Fetch existing backups for #{schedule}")

    backups =
      schedule
      |> BackupSchedule.file_name_prefix()
      |> fetch_saved_backups

    Logger.info("#{length(backups)} backup(s) fetched for #{schedule}")
    {:noreply, %{schedule | backups: backups}}
  end

  def handle_call(:state, _from, schedule), do: {:reply, schedule, schedule}

  def handle_call(:flush_backups, _from, schedule) do
    Logger.info("Flushing saved backups for #{schedule}")

    schedule
    |> BackupSchedule.file_name_prefix()
    |> flush_saved_backups

    schedule = %{schedule | backups: []}

    {:reply, schedule, schedule}
  end

  def handle_call(:run_backup, _from, schedule) do
    now = NaiveDateTime.utc_now()
    Logger.info("Running (manual) backup of #{schedule} at #{now}")
    schedule = do_run_backup(schedule, now)

    {:reply, schedule, schedule}
  end

  def handle_call({:update_fields, updated_schedule}, _from, %{backups: backups}) do
    schedule = %{updated_schedule | backups: backups}
    {:reply, schedule, schedule}
  end

  def handle_call({:delete_backup, file_name}, _from, schedule = %{backups: backups}) do
    updated_backups = Enum.filter(backups, &(&1.name != file_name))

    backups
    |> Enum.find(&(&1.name == file_name))
    |> case do
      nil ->
        {:reply, :not_found, schedule}

      backup ->
        delete_backups([backup])
        schedule = %{schedule | backups: updated_backups}
        {:reply, schedule, schedule}
    end
  end

  def handle_info(:tick, schedule) do
    schedule_next_tick()
    now = NaiveDateTime.utc_now()

    case BackupSchedule.should_run?(schedule, now) do
      false ->
        {:noreply, schedule}

      true ->
        Logger.info("Running (automatic) backup of #{schedule} at #{now}")
        {:noreply, do_run_backup(schedule, now)}
    end
  end

  #
  # Helpers
  #
  defp backup_file_path(file_name), do: "#{Utils.tmp_dir()}/#{file_name}"

  defp bucket_module, do: Application.get_env(:janitor, :bucket_store)

  defp do_run_backup(schedule = %BackupSchedule{}, date_time) do
    file_name = BackupSchedule.new_file_name(schedule, date_time)
    backup_file = backup_file_path(file_name)

    schedule
    |> BackupSchedule.backup_command(backup_file)
    |> to_charlist
    |> :os.cmd()

    backups = upload_and_prune_backups(schedule, file_name)

    Logger.info("Backup done. Removing tmp file #{backup_file}")
    File.rm(backup_file)

    %{schedule | backups: backups}
  end

  defp upload_and_prune_backups(
         %BackupSchedule{backups: backups, preserve: limit},
         file_name
       ) do
    file_name
    |> backup_file_path()
    |> bucket_module().upload_backup(file_name)
    |> case do
      {:error, _} ->
        backups

      {:ok, backup} ->
        {backups_to_be_deleted, backups} =
          backups
          |> List.insert_at(-1, backup)
          |> remove_backups_to_be_deleted(limit)

        num_to_be_deleted = length(backups_to_be_deleted)

        if num_to_be_deleted > 0 do
          Logger.info("Removing #{num_to_be_deleted} oldest backups")
        end

        delete_backups(backups_to_be_deleted)
        backups
    end
  end

  defp count_backups_to_be_deleted(count, limit) when count <= limit, do: 0
  defp count_backups_to_be_deleted(count, limit), do: count - limit

  defp remove_backups_to_be_deleted(backups, limit) do
    backups
    |> length
    |> count_backups_to_be_deleted(limit)
    |> case do
      0 ->
        {[], backups}

      num_to_be_deleted ->
        num_to_preserve = limit - num_to_be_deleted
        {Enum.take(backups, num_to_be_deleted), Enum.take(backups, -num_to_preserve)}
    end
  end

  defp delete_backups([]), do: :ok
  defp delete_backups(backups = [_ | _]), do: bucket_module().delete_backups(backups)

  defp flush_saved_backups(name), do: bucket_module().clear_backups_for_schedule(name)

  defp fetch_saved_backups(name), do: bucket_module().backups_for_schedule(name)

  defp schedule_next_tick do
    now = NaiveDateTime.utc_now()
    one_minute_later = NaiveDateTime.add(now, 60)

    Process.send_after(self(), :tick, NaiveDateTime.diff(one_minute_later, now, :millisecond))
  end
end
