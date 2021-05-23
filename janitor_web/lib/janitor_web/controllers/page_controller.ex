defmodule JanitorWeb.PageController do
  alias Janitor.Boundary.Utils
  use JanitorWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def available_databases(conn, params) do
    available =
      Utils.available_databases(
        params["host"],
        params["port"],
        params["db"],
        params["username"],
        params["password"]
      )

    json(conn, available)
  end

  def all_backup_schedules(conn, _params) do
    json(conn, Janitor.all_backup_schedules())
  end

  def create_backup_schedule(conn, params) do
    params
    |> AtomizeKeys.atomize_string_keys()
    |> Janitor.create_backup_schedule(true)
    |> case do
      {:ok, backup_schedule} ->
        conn
        |> put_status(201)
        |> json(backup_schedule)

      {:error, err} ->
        conn
        |> put_status(422)
        |> json(err)
    end
  end

  def update_backup_schedule(conn, params = %{"id" => id}) do
    id
    |> Janitor.update_backup_schedule(AtomizeKeys.atomize_string_keys(params))
    |> case do
      {:ok, backup_schedule} ->
        conn
        |> put_status(200)
        |> json(backup_schedule)

      {:error, err} ->
        conn
        |> put_status(422)
        |> json(err)
    end
  end

  def delete_backup_schedule(conn, params = %{"id" => id}) do
    id
    |> Janitor.delete_backup_schedule()
    |> case do
      :ok ->
        conn
        |> put_resp_header("content-type", "application/json")
        |> send_resp(204, "")

      err ->
        conn
        |> put_status(400)
        |> json(%{error: err})
    end
  end

  def run_backup(conn, _params = %{"id" => id}) do
    json(conn, Janitor.run_backup(id))
  end

  def delete_backup(conn, _params = %{"id" => id, "name" => file_name}) do
    json(conn, Janitor.delete_backup(id, file_name))
  end
end
