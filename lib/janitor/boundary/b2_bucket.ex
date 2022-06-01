defmodule Janitor.Boundary.B2Bucket do
  @moduledoc false
  alias ExAws.S3
  alias Janitor.Core.{Backup, BackupStore}

  @behaviour BackupStore

  @app :janitor

  require Logger

  def all_backups do
    @app
    |> Application.get_env(:bucket_name)
    |> S3.list_objects()
    |> ExAws.request()
    |> case do
      {:error, _} -> []
      {:ok, %{body: %{contents: backups}}} -> Enum.map(backups, &%Backup{name: &1.key})
    end
  end

  def backups_for_schedule(name, add_link \\ true) do
    backups = all_backups() |> Enum.filter(&String.starts_with?(&1.name, name))

    case add_link do
      false -> backups
      true -> Enum.map(backups, &add_download_link_to_backup/1)
    end
  end

  def clear_backups_for_schedule(name) do
    Logger.info("Clear backups for '#{name}'")

    case backups_for_schedule(name, false) do
      [_ | _] = backups -> delete_backups(backups)
      [] -> Logger.warn("Backups for '#{name}' does not exist or were not returned")
    end
  end

  def delete_backups(backups = [_ | _]) do
    backups
    |> Enum.each(fn %Backup{name: name} ->
      Logger.info("Deleting backup file '#{name}'")

      @app
      |> Application.get_env(:bucket_name)
      |> S3.delete_object(name)
      |> ExAws.request()
    end)
  end

  def upload_backup(file_path, file_name) do
    bucket = Application.get_env(@app, :bucket_name)
    Logger.info("Uploading #{file_name} from #{file_path}...")

    file_path
    |> S3.Upload.stream_file()
    |> S3.upload(bucket, file_name, content_type: "application/x-sql")
    |> ExAws.request()
    |> IO.inspect()
    |> case do
      {:error, {:http_error, _status_code, %{body: body}}} ->
        Logger.error("Uploading #{file_name} returned error #{body}")
        {:error, :not_uploaded}

      {:error, _} ->
        Logger.error("Uploading #{file_name} failed")
        {:error, :not_uploaded}

      {:ok, _} ->
        Logger.info("Uploading #{file_name} succeeded")
        {:ok, add_download_link_to_backup(%Backup{name: file_name})}
    end
  end

  defp get_download_link(%Backup{name: file_name}) do
    bucket_name = Application.get_env(@app, :bucket_name)
    file_path = "/file/#{bucket_name}/#{file_name}"

    case get_api_params() do
      {:ok, %{token: token, download_url: d_url}} ->
        {:ok, "#{d_url}#{file_path}?Authorization=#{token}"}

      {:error, err} ->
        Logger.warn("Fetching download link for '#{file_name}' returned #{inspect(err)}")
        {:error, :unsuccessful}
    end
  end

  defp get_api_params do
    access_key_id = Application.get_env(@app, :bucket_access_key_id)
    access_key = Application.get_env(@app, :bucket_access_key)
    auth_str = Base.encode64("#{access_key_id}:#{access_key}")
    headers = [{"authorization", "Basic #{auth_str}"}]
    api_url = Application.get_env(@app, :b2_api_url)
    auth_url = "#{api_url}/b2api/v2/b2_authorize_account"

    case make_request(auth_url, headers: headers) do
      {:ok, %{"apiUrl" => a_url, "authorizationToken" => token, "downloadUrl" => d_url}} ->
        {:ok, %{api_url: a_url, token: token, download_url: d_url}}

      {:error, _err} ->
        {:error, :unsuccessful}
    end
  end

  defp make_request(url, opts) do
    result =
      opts
      |> Keyword.get(:method, :get)
      |> Finch.build(url, build_headers(opts), Keyword.get(opts, :body))
      |> Finch.request(@app, pool_timeout: 50_000)

    case Keyword.get(opts, :decode_result, true) do
      false -> result
      true -> process_result(result, url)
    end
  end

  defp build_headers(opts) do
    headers = Keyword.get(opts, :headers, [])

    headers
    |> List.keyfind("content-type", 0)
    |> case do
      nil -> headers ++ [{"content-type", "application/json"}]
      _ -> headers
    end
    |> Kernel.++([{"accept", "application/json"}])
  end

  defp process_result(result, url) do
    case result do
      {:ok, %{body: body, status: code}} when code >= 200 and code <= 300 ->
        case Jason.decode(body, strings: :copy) do
          {:ok, json} ->
            {:ok, json}

          {:error, err} ->
            Logger.error("Decoding result from '#{url}' failed. Error: #{inspect(err)}")

            {:error, :json_decode_failed}
        end

      {:ok, %{body: body, status: code}} ->
        Logger.error("Request to '#{url}' failed with status code #{code} and body #{body}")

        {:error, :request_failed}

      {:error, %{reason: reason}} ->
        Logger.error("Request to '#{url}' failed with reason #{inspect(reason)}")

        {:error, reason}
    end
  end

  defp add_download_link_to_backup(backup = %Backup{}) do
    case get_download_link(backup) do
      {:error, _} -> backup
      {:ok, link} -> %{backup | download_link: link}
    end
  end
end
