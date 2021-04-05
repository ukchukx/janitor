defmodule Janitor.Core.BackupSchedule do
  @moduledoc false
  alias Janitor.Core.Utils

  @fields ~w[id db name host port username password frequency days times preserve backups]a
  @derive {Jason.Encoder, only: @fields}

  defstruct [
    :id,
    :db,
    :name,
    :host,
    :port,
    :username,
    :password,
    :frequency,
    :days,
    :times,
    preserve: 5,
    backups: []
  ]

  @days_of_week %{
    1 => "Monday",
    2 => "Tuesday",
    3 => "Wednesday",
    4 => "Thursday",
    5 => "Friday",
    6 => "Saturday",
    7 => "Sunday"
  }

  def new(name, db, username, opts \\ []) do
    frequency = Keyword.get(opts, :frequency, "daily")

    attrs = %{
      id: Keyword.get(opts, :id, Utils.new_id()),
      name: name,
      db: db,
      username: username,
      frequency: frequency,
      host: Keyword.get(opts, :host, "localhost"),
      port: Keyword.get(opts, :port, default_port_for(db)),
      password: Keyword.get(opts, :password),
      preserve: Keyword.get(opts, :preserve, 5),
      days: Keyword.get(opts, :days, get_default_days(frequency)),
      times: Keyword.get(opts, :times, ["12:00"]),
      backups: Keyword.get(opts, :backups, [])
    }

    struct!(__MODULE__, attrs)
  end

  def backup_command(s = %__MODULE__{db: "mysql", host: host, password: p}, out_file) do
    host =
      case host do
        "localhost" -> "127.0.0.1"
        host -> host
      end

    p =
      case p do
        nil -> ""
        p -> p
      end

    "MYSQL_PWD=\"#{p}\" mysqldump -h #{host} --port=#{s.port} -u #{s.username} #{s.name}" <>
      " > #{out_file}"
  end

  def backup_command(s = %__MODULE__{db: "postgresql", host: host, password: p}, out_file) do
    p =
      case p do
        nil -> ""
        p -> p
      end

    "PGPASSWORD='#{p}' pg_dump -U #{s.username} -h #{host} --port=#{s.port} #{s.name}" <>
      " > #{out_file}"
  end

  def backup_command(_schedule, _out_prefix), do: "echo 0"

  def new_file_name(s = %__MODULE__{}, date \\ nil) do
    date =
      case date do
        nil -> NaiveDateTime.utc_now()
        date -> date
      end

    date_str =
      date
      |> NaiveDateTime.to_iso8601()
      |> String.split(".")
      |> Enum.at(0)

    "#{file_name_prefix(s)}_#{date_str}.sql"
  end

  def file_name_prefix(%__MODULE__{name: name, db: db}), do: "#{name}_#{db}"

  def should_run?(%__MODULE__{frequency: "daily", times: times}, date) do
    same_time?(times, date)
  end

  def should_run?(%__MODULE__{frequency: "weekly", days: days, times: times}, date) do
    same_day?(days, date) and same_time?(times, date)
  end

  defp same_time?(times, date) do
    time =
      date
      |> NaiveDateTime.to_time()
      |> Time.to_string()

    Enum.any?(times, &String.starts_with?(time, &1))
  end

  defp same_day?(days, date) do
    day_index =
      date
      |> NaiveDateTime.to_date()
      |> Date.day_of_week()

    day_of_date = Map.get(@days_of_week, day_index)
    Enum.any?(days, &(&1 == day_of_date))
  end

  defp get_default_days("weekly"), do: ["sun"]
  defp get_default_days(_), do: []

  defp default_port_for("mysql"), do: 3306
  defp default_port_for("postgresql"), do: 5432
end

defimpl String.Chars, for: Janitor.Core.BackupSchedule do
  alias Janitor.Core.BackupSchedule

  def to_string(s = %BackupSchedule{}) do
    "#{s.db}://#{s.host}:#{s.port}/#{s.name}"
  end
end
