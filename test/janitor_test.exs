defmodule JanitorTest do
  alias Janitor.Core.BackupSchedule
  use ExUnit.Case, async: true

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
end
