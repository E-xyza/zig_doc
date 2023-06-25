defmodule ZigDoc.MixProject do
  use Mix.Project

  def project do
    [
      app: :zig_doc,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # zig_doc is tied to specific versions of ex_doc.
      # it uses some forbidden "private" functions.
      {:ex_doc, "== 0.29.4"}
    ]
  end
end
