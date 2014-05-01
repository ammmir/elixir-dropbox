defmodule DropboxTest do
  use ExUnit.Case

  setup_all do
    Dropbox.HTTP.start

    try do
      creds_path = Path.expand System.get_env "DB_CREDS"
      file = File.open! creds_path
      client_id = String.strip IO.read file, :line
      client_secret = String.strip IO.read file, :line
      access_token = String.strip IO.read file, :line
      File.close file

      {:ok, [client: %Dropbox.Client{client_id: client_id,
                                     client_secret: client_secret,
                                     access_token: access_token,
                                     root: :dropbox}]}
    rescue
      e ->
        IO.puts "
  Error: #{inspect e}

  You must create a file containing 3 lines:

        <your client id>
        <your client secret>
        <your access token>

  Then run mix test again with:

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

  defp random_name do
    "test-" <> :base64.encode(:crypto.rand_bytes(8)) |> String.replace(~r/[^a-zA-Z]/, "")
  end
end
