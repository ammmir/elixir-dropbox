Code.ensure_loaded?(Hex) and Hex.start

defmodule Dropbox.Mixfile do
  use Mix.Project

  def project do
    [
      app: :dropbox,
      version: "0.0.2",
      elixir: "~> 0.13.1",
      description: description,
      package: package,
      deps: deps
    ]
  end

  def application do
    [
      mod: { Dropbox, [] },
      applications: [:hackney, :exjson]
    ]
  end

  defp deps do
    [
      {:exjson, "~> 0.3.0"},
      {:hackney, github: "benoitc/hackney"}
    ]
  end

  defp description do
    "A Dropbox Core API client for Elixir"
  end

  defp package do
    [
      licenses: ["MIT"],
      links: [
        {"GitHub", "https://github.com/ammmir/elixir-dropbox"}
      ]
    ]
  end
end
