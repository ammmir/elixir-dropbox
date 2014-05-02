defmodule DropboxTest do
  use ExUnit.Case

  setup_all do
    Dropbox.HTTP.start

    try do
      creds_file = Path.expand System.get_env "DB_CREDS"

      if not File.exists? creds_file do
        IO.write "Dropbox app key: "
        client_id = String.strip IO.read :line
        IO.write "Dropbox app secret: "
        client_secret = String.strip IO.read :line

        client = %Dropbox.Client{client_id: client_id,
                                 client_secret: client_secret}

        IO.puts "To obtain a code, visit: #{Dropbox.authorize_url(client)}"
        IO.write "Enter code: "
        code = String.strip IO.read :line

        {:ok, access_token, uid} = Dropbox.access_token client, code
        client = %{client | access_token: access_token}
        {:ok, _} = Dropbox.account_info client

        File.write! creds_file, "#{client_id}\n#{client_secret}\n#{access_token}"
      end

      {:ok, [client: get_client creds_file]}
    rescue
      e ->
        IO.puts "
  Error: #{inspect e}

  You need to set the DB_CREDS environment variable for credential storage:

        DB_CREDS=~/.dropbox-test-credentials mix test"
        :bad
    end
  end

  test "get account info", ctx do
    account = Dropbox.account_info! ctx[:client]

    assert account.email != nil
    assert account.quota_info.quota > 0
  end

  test "get root folder contents", ctx do
    meta = Dropbox.metadata! ctx[:client], "/"

    assert meta.is_dir == true
    assert Enum.count(meta.contents) > 0
  end

  test "directory operations", ctx do
    dirname = random_name

    assert Dropbox.mkdir!(ctx[:client], dirname) == true
    assert Dropbox.metadata!(ctx[:client], dirname).is_dir == true
    assert Dropbox.delete!(ctx[:client], dirname) == true
  end

  test "upload and download a file", ctx do
    filename = random_name

    meta = Dropbox.upload_file! ctx[:client], "README.md", filename
    assert meta.path == "/#{filename}"
    assert File.read!("README.md") == Dropbox.download!(ctx[:client], "/#{filename}")
    assert Dropbox.delete!(ctx[:client], filename) == true
  end

  defp get_client(path) do
    file = File.open! path
    client_id = String.strip IO.read file, :line
    client_secret = String.strip IO.read file, :line
    access_token = String.strip IO.read file, :line
    File.close file

    %Dropbox.Client{client_id: client_id,
                    client_secret: client_secret,
                    access_token: access_token,
                    root: :dropbox}
  end

  defp random_name do
    "test-" <> :base64.encode(:crypto.rand_bytes(8)) |> String.replace(~r/[^a-zA-Z]/, "")
  end
end
