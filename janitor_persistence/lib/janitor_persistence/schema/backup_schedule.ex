defmodule JanitorPersistence.Schema.BackupSchedule do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @behaviour JanitorPersistence.Model

  @primary_key {:id, :binary_id, autogenerate: false}
  @fields ~w[id name db username password host port frequency preserve days times]a
  @required_fields ~w[id name db username host frequency preserve times]a

  schema "backup_schedules" do
    field(:name, :string)
    field(:db, :string)
    field(:username, :string)
    field(:password, :string)
    field(:host, :string)
    field(:port, :integer)
    field(:frequency, :string)
    field(:preserve, :integer)
    field(:days, :string)
    field(:times, :string)
    timestamps(type: :utc_datetime)
  end

  def from_model(model) do
    %{
      id: model.id,
      name: model.name,
      db: model.db,
      username: model.username,
      password: model.password,
      host: model.host,
      port: model.port,
      frequency: model.frequency,
      preserve: model.preserve,
      days: list_to_string(model.days),
      times: list_to_string(model.times),
    }
  end

  def to_map(record) do
    %{
      id: record.id,
      name: record.name,
      db: record.db,
      username: record.username,
      password: record.password,
      host: record.host,
      port: record.port,
      frequency: record.frequency,
      preserve: record.preserve,
      days: list_from_string(record.days),
      times: list_from_string(record.times),
    }
  end

  def changeset(fields), do: changeset(%__MODULE__{}, fields)

  def changeset(record = %__MODULE__{}, fields) do
    record
    |> cast(fields, @fields)
    |> validate_required(@required_fields)
  end

  defp list_to_string(nil), do: nil
  defp list_to_string([]), do: nil
  defp list_to_string(list), do: Enum.join(list, ",")

  defp list_from_string(nil), do: []
  defp list_from_string(str), do: String.split(str, ",", trim: true)
end
