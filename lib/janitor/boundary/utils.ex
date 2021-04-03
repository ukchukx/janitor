defmodule Janitor.Boundary.Utils do
  @moduledoc false

  @spec child_pid?(tuple, atom) :: boolean
  @spec id_from_pid(tuple, atom, atom) :: [binary]

  def child_pid?({:undefined, pid, :worker, [mod]}, mod) when is_pid(pid), do: true
  def child_pid?(_child, _module), do: false

  def id_from_pid({:undefined, pid, :worker, [mod]}, registry, mod),
    do: Registry.keys(registry, pid)

  def available_databases(host, port, "postgresql", user, password) do
    command =
      "PGPASSWORD='#{password}' psql -d postgres -U #{user} -h #{host} --port=#{port} -c 'select datname from pg_database;'"

    command
    |> to_charlist
    |> :os.cmd()
    |> :erlang.list_to_binary()
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(fn
      "" ->
        false

      str ->
        str
        |> is_not_row_count?()
        |> Kernel.and(is_not_datname?(str))
        |> Kernel.and(is_not_made_up_of_dashes?(str))
    end)
  end

  def available_databases(host, port, "mysql", user, password) do
    host =
      case host do
        "localhost" -> "127.0.0.1"
        host -> host
      end

    command =
      "MYSQL_PWD='#{password}' mysql -h #{host} --port=#{port} -u #{user} -e 'show databases;'"

    command
    |> to_charlist
    |> :os.cmd()
    |> :erlang.list_to_binary()
    |> String.split("\n")
    |> Enum.filter(fn
      "Database" -> false
      "" -> false
      _ -> true
    end)
  end

  def tmp_dir, do: System.tmp_dir()

  defp is_not_row_count?(str) do
    str
    |> String.starts_with?("(")
    |> Kernel.and(String.ends_with?(str, "rows)"))
    |> Kernel.not()
  end

  defp is_not_made_up_of_dashes?(str) do
    str
    |> String.replace("-", "")
    |> Kernel.==("")
    |> Kernel.not()
  end

  defp is_not_datname?(str) do
    str
    |> String.trim()
    |> Kernel.==("datname")
    |> Kernel.not()
  end
end
