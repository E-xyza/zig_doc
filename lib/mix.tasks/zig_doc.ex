defmodule Mix.Tasks.ZigDoc do
  use Mix.Task

  @shortdoc "Generate documentation for the project"
  @requirements ["compile"]

  @spec run([String.t()], keyword) :: :ok
  @moduledoc """

  see `Mix.Tasks.Docs` for more information
  """
  def run(params, zig_doc_options \\ []) do
    # TODO: make sure update works with lambdas
    config =
      Mix.Project.config()
      |> Keyword.update(:docs, zig_doc_options, &Keyword.merge(&1, zig_doc_options))

    Mix.Tasks.Docs.run(params, config, &Zig.Doc.generate_docs/3)
    :ok
  end
end

defmodule Mix.Tasks.ZigDocDev do
  def run(params) do
    Mix.Tasks.ZigDoc.run(params, zig_doc: [])
  end
end
