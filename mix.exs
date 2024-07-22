defmodule ZigDoc.MixProject do
  use Mix.Project

  def project do
    [
      app: :zig_doc,
      version: "0.4.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      package: [
        description: "Zig documentation library for zigler",
        licenses: ["MIT"],
        files: ~w(lib mix.exs README* LICENSE*),
        links: %{
          "GitHub" => "https://github.com/E-xyza/zig_doc",
          "Zigler" => "https://hexdocs.pm/zigler"
        }
      ],
      docs: [main: "Zig.Doc"],
      source_url: "https://github.com/E-xyza/zig_doc/",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/_support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # zig_doc is tied to specific versions of ex_doc.
      # it uses some forbidden "private" functions.
      {:ex_doc, "~> 0.34.2"},
      # this is also pinned to a version of zig_parser because
      # versions of zig_parser are pinned to zig versions.
      {:zig_parser, "~> 0.4.0"},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
