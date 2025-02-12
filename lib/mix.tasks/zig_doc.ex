defmodule Mix.Tasks.ZigDoc do
  use Mix.Task

  @shortdoc "Generate documentation for the project"
  @requirements ["compile"]

  @spec run([String.t()], keyword) :: :ok
  @moduledoc """
  Runs `mix docs`, except with `Zig.Doc.generate_docs/3` as the callback.

  This injects a processing step for zig documentation at the end of the mix
  doc step, including specified zig files as "modules" in the ExDoc system.
  These files are incorporated under the `ZIG CODE` module category.

  This is most effectively used by aliasing it in your mix.exs:

  ```elixir
  def project do
    [
      ...
      aliases: [
        docs: ["zig_doc"]
      ]
      ...
    ]
  end
  ```

  see `Mix.Tasks.Docs` for more information
  """
  def run(params, zig_doc_options \\ []) do
    config =
      Mix.Project.config()
      |> Keyword.update(:docs, zig_doc_options, &Keyword.merge(&1, zig_doc_options))

    Makeup.Lexers.ElixirLexer.register_sigil_lexer("Z", MakeupSyntect.Lexer, [language: "zig"])

    Mix.Tasks.Docs.run(params, config, &Zig.Doc.generate_docs/3)
    :ok
  end
end
