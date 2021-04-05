defmodule JanitorTest do
  alias Janitor.Core.BackupSchedule
  use ExUnit.Case

  setup do
    Janitor.clear_backups_from_db()
  end

  test "backup schedules don't run outside their set time" do
    date = ~N[2021-04-03 12:01:00]
    refute BackupSchedule.should_run?(sample_daily_schedule(), date)
    refute BackupSchedule.should_run?(sample_weekly_schedule(), date)
  end

  test "backup schedules run at their set time" do
    date = ~N[2021-04-03 12:00:00]
    assert BackupSchedule.should_run?(sample_daily_schedule(), date)
    assert BackupSchedule.should_run?(sample_weekly_schedule(), date)
  end

  test "backup schedules can be created" do
    %{id: id} =
      sample_daily_schedule()
      |> Map.from_struct()
      |> Map.drop([:__struct__])
      |> Janitor.create_backup_schedule()
      |> elem(1)
      |> Janitor.start_schedule()

    assert {:ok, %BackupSchedule{}} = Janitor.get_backup_schedule(id)
  end

  test "backup schedules can be updated" do
    %{id: id} =
      sample_weekly_schedule()
      |> Map.from_struct()
      |> Map.drop([:__struct__])
      |> Janitor.create_backup_schedule()
      |> elem(1)
      |> Janitor.start_schedule()

    {:ok, %BackupSchedule{name: updated_name}} = Janitor.update_backup_schedule(id, %{name: "a"})
    assert "a" == updated_name
  end

  test "backup schedules can be listed" do
    sample_daily_schedule() |> Janitor.start_schedule()
    sample_weekly_schedule() |> Janitor.start_schedule()

    assert 2 == Janitor.all_backup_schedules() |> length
  end

  defp sample_daily_schedule do
    BackupSchedule.new("x", "mysql", "root", times: ["12:00", "22:00"], frequency: "daily")
  end

  defp sample_weekly_schedule do
    BackupSchedule.new("y", "postgresql", "postgres",
      times: ["12:00", "22:00"],
      days: ["mon", "sat"],
      frequency: "weekly"
    )
  end
end
