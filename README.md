# elixir-dropbox

A Dropbox Core API client for Elixir, based on [hackney](https://github.com/benoitc/hackney) and [Jazz](https://github.com/meh/jazz).

The Dropbox module provides the thinnest layer of abstraction as possible on top of the Dropbox Core API. Responses are returned as maps and use the same field names as the API itself to keep things simple.

UNDER DEVELOPMENT, NOT READY FOR PRODUCTION USE! Contributions welcome :)

## Usage

```iex
iex> Dropbox.start
:ok
iex> client = %Dropbox.Client{access_token: "WAAAwaaaWAAAWaaaaWaaWaaa..."}
%Dropbox.Client{access_token: "WAAAwaaaWAAAWaaaaWaaWaaa...",
 client_id: nil, client_secret: nil, locale: nil, root: :dropbox}
iex> Dropbox.account_info! client
 %Dropbox.Account{country: "US", display_name: "Amir Malik", email: "amir@example.com",
  quota_info: %{normal: 0, quota: 2952790016, shared: 21122088},
  referral_link: "https://db.tt/uLPPUkc", team: nil, uid: 31337}
iex> Dropbox.mkdir! client, "secrets"
true
iex> Dropbox.upload_file! client, "/etc/passwd", "secrets/lol"
%Dropbox.Metadata{bytes: 5253, client_mtime: "Thu, 01 May 2014 07:01:46 +0000", 
 contents: %{}, hash: nil, icon: "page_white", is_deleted: false, is_dir: false,
 modified: "Thu, 01 May 2014 07:01:46 +0000", path: "/secrets/lol",
 photo_info: %Dropbox.Metadata.Photo{lat_long: [], time_taken: nil},
 rev: "6800b928df", size: "5.1 KB", thumb_exists: false,
 video_info: %Dropbox.Metadata.Video{duration: 0, lat_long: [], time_taken: nil}}
```

Nearly all functions have bang (!) equivalents, which raise exceptions on errors instead of returning `{:error, reason}` tuples.
