Code.ensure_loaded?(Hex) and Hex.start

defmodule Dropbox.Mixfile do
  use Mix.Project

  def project do
    [
      app: :dropbox,
      version: "0.0.6",
      elixir: ">= 0.14.3",
      description: description,
      package: package,
      deps: deps
    ]
  end

  def application do
    [
      mod: { Dropbox, [] },
      applications: [:hackney]
    ]
  end

  defp deps do
    [
      {:jazz, "~> 0.1.2"},
      {:hackney, github: "benoitc/hackney"}
    ]
  end

  defp description do
    "A Dropbox Core API client for Elixir"
  end

  defp package do
    [
      contributors: ["Amir Malik"],
      licenses: ["MIT"],
      links: [
        {"GitHub", "https://github.com/ammmir/elixir-dropbox"}
      ]
    ]
  end
end
