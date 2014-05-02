defmodule Dropbox do
  @moduledoc """
  Provides an interface to the Dropbox Core API.
  """

  defexception Error, message: nil, status: 0

  defmodule Client do
    defstruct client_id: nil,
              client_secret: nil,
              access_token: nil,
              locale: nil,
              root: :dropbox
  end

  defmodule Account do
    defstruct email: nil,
              referral_link: nil,
              display_name: nil,
              uid: nil,
              country: nil,
              team: %{name: nil},
              quota_info: %{normal: 0, shared: 0, quota: 0}
  end

  defmodule Metadata do
    defmodule Photo do
      defstruct lat_long: [],
                time_taken: nil
    end

    defmodule Video do
      defstruct lat_long: [],
                time_taken: nil,
                duration: 0
    end

    defstruct size: nil,
              bytes: 0,
              path: nil,
              is_dir: false,
              is_deleted: false,
              rev: nil,
              hash: nil,
              thumb_exists: false,
              photo_info: %Photo{},
              video_info: %Video{},
              icon: nil,
              modified: nil,
              client_mtime: nil,
              contents: %{}
  end

  def start do
    Dropbox.HTTP.start
  end

  def start(_type, _args) do
    start
    {:ok, self}
  end

  ### OAuth 2.0: optional, can be handled by third-party lib or manually ###

  def authorize_url(client, redirect_uri \\ nil, state \\ "") do
    query = %{
      client_id: client.client_id,
      response_type: "code",
      state: state
    }
    if redirect_uri do
      query = Map.put query, :redirect_uri, redirect_uri
    end

    "https://www.dropbox.com/1/oauth2/authorize?#{URI.encode_query query}"
  end

  def access_token(client, code) do
    case Dropbox.HTTP.post client, "https://api.dropbox.com/1/oauth2/token?grant_type=authorization_code&code=#{URI.encode code}", nil, %{access_token: nil, uid: nil} do
      {:ok, token} -> {:ok, token.access_token, token.uid}
      e -> e
    end
  end

  def disable_access_token(client) do
    case Dropbox.HTTP.post client, "https://api.dropbox.com/1/disable_access_token" do
      {:ok, _} -> :ok
      e -> e
    end
  end

  ### Dropbox accounts ###

  def account_info(client) do
    Dropbox.HTTP.get client, "https://api.dropbox.com/1/account/info", Dropbox.Account
  end

  def account_info!(client) do
    case account_info client do
      {:ok, info} -> info
      {:error, reason} -> raise_error reason
    end
  end

  ### Files and metadata ###

  def download(client, path, rev \\ nil) do
    Dropbox.HTTP.get client, "https://api-content.dropbox.com/1/files/#{client.root}#{normalize_path path}#{if rev do "?rev=" <> rev end}", Dropbox.Metadata
  end

  def download!(client, path, rev \\ nil) do
    case download client, path, rev do
      {:ok, meta, contents} -> contents
      {:error, reason} -> raise_error reason
    end
  end

  def download_file(client, path, local_path, rev \\ nil) do
  end

  def upload_file(client, local_path, remote_path, overwrite \\ true, parent_rev \\ nil) do
    query = %{
      overwrite: overwrite
    }

    if parent_rev do
      query = Map.put query, :parent_rev, parent_rev
    end

    Dropbox.HTTP.put client, "https://api-content.dropbox.com/1/files_put/#{client.root}#{normalize_path remote_path}", {:file, local_path}, Dropbox.Metadata
  end

  def upload_file!(client, local_path, remote_path, overwrite \\ true, parent_rev \\ nil) do
    case upload_file client, local_path, remote_path do
      {:ok, meta} -> meta
      {:error, reason} -> raise_error reason
    end
  end

  def metadata(client, path, options \\ []) do
    case Dropbox.HTTP.get client, "https://api.dropbox.com/1/metadata/#{client.root}#{normalize_path path}", Dropbox.Metadata do
      {:ok, meta} ->
        {:ok, Map.put(meta, :contents, Enum.map(meta.contents, fn(x) -> Dropbox.Util.atomize_map Dropbox.Metadata, x end))}
      e -> e
    end
  end

  def metadata!(client, path, options \\ []) do
    case metadata client, path, options do
      {:ok, meta} -> meta
      {:error, reason} -> raise_error reason
    end
  end

  def delta(client, cursor=nil, path_prefix=nil, media=false) do
  end

  def wait_for_change(client, cursor, timeout=30) do
  end

  def revisions(client, path, limit=10) do
  end

  def restore(client, path, rev) do
  end

  def search(client, path, query, limit=1000, deleted=false) do
  end

  def share_link(client, path, short=false) do
  end

  def media_url(client, path) do
  end

  def copy_ref(client, path) do
  end

  def copy_ref!(client, path) do
  end

  def thumbnail(client, path, size \\ :s, format \\ :jpeg) do
  end

  def upload_chunk(client, upload_id, offset, data) do
  end

  def commit_chunked_upload(client, upload_id, path, overwrite \\ true, parent_rev \\ nil) do
  end

  ### File operations ###

  def copy(client, from_path, to_path) do
    query = %{
      root: client.root,
      from_path: from_path,
      to_path: to_path
    }

    Dropbox.HTTP.post client, "https://api.dropbox.com/1/fileops/copy?#{URI.encode_query query}"
  end

  def copy!(client, from_path, to_path) do
    case copy client, from_path, to_path do
      {:ok, meta} -> true
      _ -> false
    end
  end

  def copy_from_ref(client, from_copy_ref, to_path) do
    query = %{
      root: client.root,
      from_copy_ref: from_copy_ref,
      to_path: to_path
    }

    Dropbox.HTTP.post client, "https://api.dropbox.com/1/fileops/copy?#{URI.encode_query query}", Dropbox.Metadata
  end

  def copy_from_ref!(client, from_copy_ref, to_path) do
    case copy_from_ref client, from_copy_ref, to_path do
      {:ok, _} -> true
      {:error, reason} -> raise_error reason
    end
  end

  def mkdir!(client, path) do
    query = %{
      root: client.root,
      path: path
    }

    case Dropbox.HTTP.post client, "https://api.dropbox.com/1/fileops/create_folder?#{URI.encode_query query}", Dropbox.Metadata do
      {:ok, meta} -> true
      _ -> false
    end
  end

  def delete(client, path) do
    query = %{
      root: client.root,
      path: path
    }

    Dropbox.HTTP.post client, "https://api.dropbox.com/1/fileops/delete?#{URI.encode_query query}"
  end

  def delete!(client, path) do
    case delete client, path do
      {:ok, _} -> true
      {:error, reason} -> raise_error reason
    end
  end

  def move(client, from_path, to_path) do
    query = %{
      root: client.root,
      from_path: from_path,
      to_path: to_path
    }

    Dropbox.HTTP.post client, "https://api.dropbox.com/1/fileops/move?#{URI.encode_query query}"
  end

  def move!(client, from_path, to_path) do
    case move client, from_path, to_path do
      {:ok, _} -> true
      {:error, reason} -> raise_error reason
    end
  end

  defp raise_error(reason) do
    {:error, {{:http_status, code}, reason}} = reason
    raise Dropbox.Error[message: reason, status: code]
  end

  defp normalize_path(path) do
    if String.starts_with? path, "/" do
      path
    else
      "/#{path}"
    end
  end
end
