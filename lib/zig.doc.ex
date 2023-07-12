defmodule Zig.Doc do
  @moduledoc """
  Incorporates Zig documentation from selected files into Elixir projects.

  ## Usage

  1. Include the zig files you wish to document in your project docs:
    ```elixir
      def project do
        [
          docs: [
            ...
            zig_doc: [name_of_module: [file: "path/to/file.zig"]]
          ]
        ]
      end
    ```

  2. (optional) alias `Zig.Doc` in your `mix.exs`:
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
    > ### Note {: .info }
    >
    > This step is required if you want HexDocs.pm to include the zig
    > documentation with your main documentation.

  ## Documentation forms

  Currently, Zigler recognizes the following forms of documentation:

  - **files**

    This form is set using the `//!` at the top of a document, and will
    be used as the "module-level" documentation for the ExDoc result.

  - **functions**

    Public functions: `pub const <identifier> = <value that is a function>;`
    and publicly declared functions: `pub fn <identifier>(<arguments>) <type> { <block> }`
    are both recognized and converted to ExDoc-style function documentation.

  - **types**

    `pub const <type> = <expression that is a type>;` is recognized and
    converted into ExDoc-style type documentation.

  - **constants**

    `pub const <identifier> = <expression that is a constant>;` is recognized
    and converted into ExDoc-style function documentation under the category
    `Constants`.

  - **variables**

    `pub var <identifier> = ...;` is recognized and converted into ExDoc-style
    function documentation under the category `Variables`.

  > ### Warning {: .warning }
  >
  > Currently `Zig.Doc` is lazily written to support the use case for `beam.zig`
  > found in the the main Zigler project.  It is very likely that custom zig files
  > used in a nif might not be correctly parsed.  If you find this to be the case,
  > please file an issue at: https://github.com/E-xyza/zig_doc/issues
  """

  alias Zig.Doc.Generator

  @doc """
  Generates documentation for the given `project`, `vsn` (version)
  and `options`.

  Lifted and modified from `ExDoc.generate_docs` in ex_doc 0.29.4.
  """
  @spec generate_docs(String.t(), String.t(), Keyword.t()) :: atom
  def generate_docs(project, vsn, options)
      when is_binary(project) and is_binary(vsn) and is_list(options) do
    # retrieve zig_doc specific options and remove them
    {zig_doc_options, options} =
      case Keyword.pop(options, :zig_doc) do
        {nil, _} ->
          Mix.raise("zig_doc option not found in Mix.Project.config/0")

        tuple ->
          tuple
      end

    config = ExDoc.Config.build(project, vsn, options)

    if processor = options[:markdown_processor] do
      ExDoc.Markdown.put_markdown_processor(processor)
    end

    docs =
      config.source_beam
      |> config.retriever.docs_from_dir(config)
      |> add_zig_doc_config(config, zig_doc_options)

    find_formatter(config.formatter).run(docs, config)
  end

  @doc false
  def add_zig_doc_config(docs, exdoc_config, zig_doc_options, sema_module \\ Zig.Sema) do
    docs ++
      Enum.map(zig_doc_options, &Generator.modulenode_from_config(&1, exdoc_config, sema_module))
  end

  ################################################################
  #
  # private functions lifted from ExDoc:

  # Short path for programmatic interface
  defp find_formatter(modname) when is_atom(modname), do: modname

  defp find_formatter("ExDoc.Formatter." <> _ = name) do
    [name]
    |> Module.concat()
    |> check_formatter_module(name)
  end

  defp find_formatter(name) do
    [ExDoc.Formatter, String.upcase(name)]
    |> Module.concat()
    |> check_formatter_module(name)
  end

  defp check_formatter_module(modname, argname) do
    if Code.ensure_loaded?(modname) do
      modname
    else
      raise "formatter module #{inspect(argname)} not found"
    end
  end
end
