defmodule JanitorPersistence do
  @moduledoc false
  use GenServer

  @behaviour JanitorPersistence.Model

  @db_name "/janitor.db"
  @test_db_name "/janitor_test.db"
  @table_name :janitor_table

  require Logger

  def from_model(model), do: model

  def to_map(record), do: Map.from_struct(record)

  def save_backup_schedule(backup_schedule) do
    GenServer.call(__MODULE__, {:save_backup_schedule, backup_schedule})
  end

  def all_backup_schedules, do: GenServer.call(__MODULE__, :all_backup_schedules)

  def clear_backups do
    GenServer.call(__MODULE__, :clear_backups)
  end

  def delete_backup_schedule(schedule_id) do
    GenServer.call(__MODULE__, {:delete, schedule_id})
  end

  def start_link(_),
    do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__, hibernate_after: 5_000)

  def init(state) do
    db_dir = Application.get_env(:janitor_persistence, :db_dir)
    db_name =
      case Application.get_env(:janitor_persistence, :env) == :test do
        true -> @test_db_name
        false -> @db_name
      end

    db_location = Path.expand(db_dir <> db_name)
    Logger.info("DB file location: #{db_location}")

    if !File.exists?(db_dir) do
      File.mkdir_p(db_dir)
    end

    PersistentEts.new(@table_name, db_location, [:public, :named_table])

    if db_name == @test_db_name do
      :ets.delete_all_objects(@table_name)
    end

    stored_data =
      @table_name
      |> :ets.tab2list()
      |> Enum.map(fn {_, x} -> x end)
      |> Enum.reduce(%{}, fn obj, map -> Map.put(map, obj.id, obj) end)

    num_items = stored_data |> Map.keys() |> length()
    Logger.info("Fetched #{num_items} persisted records")

    {:ok, Map.put(state, :data, stored_data)}
  end

  def handle_call({:save_backup_schedule, obj}, _from, %{data: data} = state) do
    converted_obj = to_map(obj)
    :ets.insert(@table_name, {obj.id, converted_obj})
    {:reply, obj, %{state | data: Map.put(data, obj.id, converted_obj)}}
  end

  def handle_call({:delete, id}, _from, %{data: data} = state) do
    :ets.delete(@table_name, id)
    {:reply, :ok, %{state | data: Map.delete(data, id)}}
  end

  def handle_call(:clear_backups, _from, state) do
    :ets.delete_all_objects(@table_name)
    {:reply, :ok, %{state | data: %{}}}
  end

  def handle_call(:all_backup_schedules, _from, %{data: data} = state) do
    {:reply, Map.values(data), state}
  end
end
