import Dropbox.Util

defmodule Dropbox.HTTP do
  def start do
    :hackney.start
  end

  def get(client, url, res_struct \\ nil, stream_pid \\ nil) do
    do_request client, :get, url, nil, res_struct, stream_pid
  end

  def post(client, url, body \\ nil, res_struct \\ nil) do
    do_request client, :post, url, body, res_struct
  end

  def put(client, url, body, res_struct \\ nil) do
    do_request client, :put, url, body, res_struct
  end

  defp do_request(client, method, url, body, res_struct, stream_pid \\ nil) do
    if client.access_token do
      headers = [{"Authorization", "Bearer #{client.access_token}"}]
    else
      headers = [{"Authorization", "Basic #{Base.encode64 client.client_id <> ":" <> client.client_secret}"}]
    end

    case body do
      {:json, json} ->
        headers = [{"Content-Type", "application/json"} | headers]
        body = Jazz.encode! json
      {:file, _path} -> true
      _ -> body = []
    end

    options = [{:pool, :default}]

    if stream_pid do
      options = [:async, {:stream_to, stream_pid} | options]
    end

    case :hackney.request method, url, headers, body, options do
      {:ok, code, headers, body_ref} ->
        {:ok, body} = :hackney.body body_ref

        download = false

        case Enum.find headers, fn({k,_}) -> k == "x-dropbox-metadata" end do
          {_, meta} ->
            download = true
            json = atomize_map Dropbox.Metadata, Jazz.decode!(meta)
          nil ->
            json = Jazz.decode!(body)
        end

        cond do
          code in 200..299 ->
            if download do
              {:ok, atomize_map(res_struct, json), body}
            else
              {:ok, atomize_map(res_struct, json)}
            end
          code in 400..599 ->
            {:error, {{:http_status, code}, json["error"]}}
          true ->
            {:error, json}
        end
      e -> e
    end
  end
end
