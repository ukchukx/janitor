defmodule Janitor.Boundary.BackupScheduleManager do
  @moduledoc false

  alias Janitor.Boundary.{B2Bucket, Utils}
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
      true -> id |> via |> GenServer.call(:flush_backups, 20_000)
      false -> :not_running
    end
  end

  def run_backup(id) do
    case running?(id) do
      true -> id |> via |> GenServer.call(:run_backup, 20_000)
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

    {:reply, :ok, %{schedule | backups: []}}
  end

  def handle_call(:run_backup, _from, schedule) do
    Logger.info("Running (manual) backup for #{schedule}")

    {:reply, :ok, do_run_backup(schedule, NaiveDateTime.utc_now())}
  end

  def handle_info(:tick, schedule) do
    Logger.info("Running (automatic) backup for #{schedule}")
    schedule_next_tick()
    {:noreply, do_run_backup(schedule, NaiveDateTime.utc_now())}
  end

  #
  # Helpers
  #

  defp do_run_backup(schedule = %BackupSchedule{}, date_time) do
    case BackupSchedule.should_run?(schedule, date_time) do
      false ->
        schedule

      true ->
        Logger.info("Running backup of #{schedule} at #{date_time}")
        temp_dir = Utils.tmp_dir()
        file_name = BackupSchedule.new_file_name(schedule, date_time)
        backup_file = "#{temp_dir}#{file_name}"

        schedule
        |> BackupSchedule.backup_command(backup_file)
        |> to_charlist
        |> :os.cmd()

        backups = upload_and_prune_backups(schedule, temp_dir, file_name)

        Logger.info("Backup done. Removing tmp file #{backup_file}")
        File.rm(backup_file)

        %{schedule | backups: backups}
    end
  end

  defp upload_and_prune_backups(
         %BackupSchedule{backups: backups, preserve: limit},
         temp_dir,
         file_name
       ) do
    case B2Bucket.upload_backup("#{temp_dir}#{file_name}", file_name) do
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
  defp delete_backups(backups = [_ | _]), do: B2Bucket.delete_backups(backups)

  defp flush_saved_backups(name), do: B2Bucket.clear_backups_for_schedule(name)

  defp fetch_saved_backups(name), do: B2Bucket.backups_for_schedule(name)

  defp schedule_next_tick do
    now = NaiveDateTime.utc_now()
    one_minute_later = NaiveDateTime.add(now, 60)

    Process.send_after(self(), :tick, NaiveDateTime.diff(one_minute_later, now, :millisecond))
  end
end
