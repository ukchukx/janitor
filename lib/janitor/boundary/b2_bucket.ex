defmodule Janitor.Boundary.B2Bucket do
  @moduledoc false
  alias Janitor.Core.{Backup, BackupStore}

  @behaviour BackupStore

  @app :janitor

  require Logger

  def all_backups do
    bucket_id = Application.get_env(@app, :bucket_id)
    api_path = "/b2api/v2/b2_list_file_names"

    with {:ok, params} <- get_api_params(),
         headers = [{"authorization", params.token}],
         url = "#{params.api_url}#{api_path}?bucketId=#{bucket_id}",
         {:ok, %{"files" => files}} <- make_request(url, headers: headers) do
      files
      |> Enum.map(fn file = %{"fileId" => id} -> %Backup{id: id, name: file["fileName"]} end)
    else
      {:error, _} -> []
    end
  end

  def backups_for_schedule(name) do
    all_backups()
    |> Enum.filter(&String.starts_with?(&1.name, name))
    |> Enum.map(&add_download_link_to_backup/1)
  end

  def clear_backups_for_schedule(name) do
    Logger.info("Clear backups for '#{name}'")

    case backups_for_schedule(name) do
      [_ | _] = backups -> delete_backups(backups)
      [] -> Logger.warn("Backups for '#{name}' does not exist or were not returned")
    end
  end

  def delete_backups(backups = [_ | _]) do
    api_path = "/b2api/v2/b2_delete_file_version"

    case get_api_params() do
      {:ok, params} ->
        headers = [{"authorization", params.token}]

        backups
        |> Enum.each(fn %{id: id, name: name} ->
          Logger.info("Deleting backup file '#{name}'")
          url = "#{params.api_url}#{api_path}?fileId=#{id}&fileName=#{name}"
          make_request(url, headers: headers, decode_result: false)
        end)

      {:error, _} ->
        :ok
    end
  end

  def upload_backup(file_path, file_name) do
    bucket_id = Application.get_env(@app, :bucket_id)
    file_data = File.read!(file_path)
    %{size: file_size} = File.stat!(file_path)

    data_sha_1 =
      :crypto.hash(:sha, file_data)
      |> Base.encode16()
      |> String.downcase()

    encoded_file_name = URI.encode(file_name)

    common_headers = [
      {"x-bz-file-name", encoded_file_name},
      {"x-bz-content-sha1", data_sha_1},
      {"content-length", "#{file_size}"},
      {"content-type", "application/x-sql"}
    ]

    with {:ok, params} <- get_upload_url(bucket_id),
         headers = [{"authorization", params.token}] ++ common_headers,
         url = params.api_url,
         opts = [headers: headers, body: file_data, method: :post],
         {:ok, %{"fileId" => id, "fileName" => name}} <- make_request(url, opts) do
      Logger.info("Uploading #{file_name} succeeded")
      {:ok, add_download_link_to_backup(%Backup{id: id, name: name})}
    else
      {:error, _} ->
        Logger.info("Uploading #{file_name} failed")
        {:error, :not_uploaded}
    end
  end

  defp get_download_link(%Backup{name: file_name}) do
    bucket_name = Application.get_env(@app, :bucket_name)
    file_path = "/file/#{bucket_name}/#{file_name}"

    case get_api_params() do
      {:ok, %{token: token, download_url: d_url}} ->
        {:ok, %{url: "#{d_url}#{file_path}", authorization: token}}

      {:error, err} ->
        Logger.error("Fetching download link for '#{file_name}' returned #{inspect(err)}")
        {:error, :unsuccessful}
    end
  end

  defp get_upload_url(bucket_id) do
    with {:ok, params} <- get_api_params(),
         url = "#{params.api_url}/b2api/v2/b2_get_upload_url?bucketId=#{bucket_id}",
         opts = [headers: [{"authorization", params.token}]],
         {:ok, %{"uploadUrl" => url, "authorizationToken" => token}} <- make_request(url, opts) do
      {:ok, %{api_url: url, token: token}}
    else
      {:error, _} -> {:error, :could_not_get_upload_url}
    end
  end

  defp get_api_params do
    access_key_id = Application.get_env(@app, :bucket_access_key_id)
    access_key = Application.get_env(@app, :bucket_access_key)
    auth_str = Base.encode64("#{access_key_id}:#{access_key}")
    headers = [{"authorization", "Basic #{auth_str}"}]
    auth_url = "https://api.backblazeb2.com/b2api/v2/b2_authorize_account"

    case make_request(auth_url, headers: headers) do
      {:ok, %{} = map} ->
        %{"apiUrl" => a_url, "authorizationToken" => token, "downloadUrl" => d_url} = map
        {:ok, %{api_url: a_url, token: token, download_url: d_url}}

      {:error, _err} ->
        {:error, :unsuccessful}
    end
  end

  defp make_request(path, opts) do
    url = convert_path_to_url(path)
    headers = build_headers(opts)

    result =
      opts
      |> Keyword.get(:method, :get)
      |> Finch.build(url, headers, Keyword.get(opts, :body))
      |> Finch.request(@app, pool_timeout: 50_000)

    case Keyword.get(opts, :decode_result, true) do
      false -> result
      true -> process_result(result, url)
    end
  end

  defp convert_path_to_url(path) when is_binary(path) do
    path
    |> String.starts_with?("http")
    |> case do
      true -> path
      false -> URI.encode("#{bucket_host()}#{path}")
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

  defp bucket_host, do: Application.get_env(@app, :bucket_id_host)

  defp add_download_link_to_backup(backup = %Backup{meta: meta}) do
    case get_download_link(backup) do
      {:error, _} -> backup
      {:ok, link_record} -> %{backup | meta: Map.put(meta, :download_link, link_record)}
    end
  end
end
