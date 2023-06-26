defmodule ZigDoc.MixProject do
  use Mix.Project

  def project do
    [
      app: :zig_doc,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
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
      {:ex_doc, "== 0.29.4"},
      {:zig_parser, "~> 0.1.0"},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
