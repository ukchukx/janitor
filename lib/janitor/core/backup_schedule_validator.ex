defmodule Janitor.Core.BackupScheduleValidator do
  @moduledoc false
  import Janitor.Core.Validator

  def errors(fields) when is_map(fields) do
    []
    |> require(fields, :db, &validate_db/1)
    |> require(fields, :username, &validate_string/1)
    |> require(fields, :name, &validate_string/1)
    |> optional(fields, :requency, &validate_frequency/1)
    |> optional(fields, :host, &validate_host/1)
    |> optional(fields, :port, &validate_port/1)
    |> optional(fields, :password, &validate_password/1)
    |> optional(fields, :preserve, &validate_preserve/1)
    |> optional(fields, :times, &validate_times/1)
  end

  def errors(_fields), do: [{nil, "A map of fields is required"}]

  def validate_string(x) do
    check(is_binary(x), {:error, "is not a string"})
  end

  def validate_host(nil), do: :ok

  def validate_host(host) do
    check(is_binary(host), {:error, "is not a string"})
  end

  def validate_password(nil), do: :ok

  def validate_password(password) do
    check(is_binary(password), {:error, "is not a string"})
  end

  def validate_preserve(nil), do: :ok

  def validate_preserve(preserve) do
    check(is_integer(preserve), {:error, "is not an integer"})
  end

  def validate_times(nil), do: :ok

  def validate_times(times) do
    times
    |> is_list()
    |> Kernel.and(Enum.any?(times, &(is_binary(&1) and String.length(&1) == 5)))
    |> check({:error, "is not a list of time strings"})
  end

  def validate_port(nil), do: :ok

  def validate_port(port) do
    check(is_number(port), {:error, "is not an integer"})
  end

  def validate_frequency(nil), do: :ok

  def validate_frequency(freq) do
    check(
      Enum.any?(["daily", "weekly"], &(&1 == freq)),
      {:error, "should only be 'daily' or 'weekly'"}
    )
  end

  def validate_db("mysql"), do: :ok
  def validate_db("postgresql"), do: :ok
  def validate_db(_db), do: {:error, "must either be 'mysql' or 'postgresql'"}

  def validate_days(nil), do: :ok

  def validate_days(times) do
    times
    |> is_list()
    |> Kernel.and(Enum.any?(times, &(is_binary(&1) and String.length(&1) == 5)))
    |> check({:error, "is not a list of time strings"})
  end
end
