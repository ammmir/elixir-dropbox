import Dropbox.Util

defmodule Dropbox.HTTP do
  def start do
    :hackney.start
  end

  def get(client, url, res_struct \\ nil) do
    do_request client, :get, url, nil, res_struct
  end

  def post(client, url, body \\ nil, res_struct \\ nil) do
    do_request client, :post, url, body, res_struct
  end

  def put(client, url, body, res_struct \\ nil) do
    do_request client, :put, url, body, res_struct
  end

  defp do_request(client, method, url, body, res_struct) do
    if client.access_token do
      headers = [{"Authorization", "Bearer #{client.access_token}"}]
    else
      headers = [{"Authorization", "Basic #{Base.encode64 client.client_id <> ":" <> client.client_secret}"}]
    end

    case body do
      {:json, json} ->
        headers = [{"Content-Type", "application/json"} | headers]
        body = ExJSON.generate json
      {:file, path} -> true
      _ -> body = []
    end

    case :hackney.request method, url, headers, body, [{:pool, :default}] do
      {:ok, code, headers, body_ref} ->
        {:ok, body} = :hackney.body body_ref

        download = false

        case Enum.find headers, fn({k,v}) -> k == "x-dropbox-metadata" end do
          {_, meta} ->
            download = true
            json = ExJSON.parse(meta, :to_map)
          nil ->
            json = ExJSON.parse(body, :to_map)
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
