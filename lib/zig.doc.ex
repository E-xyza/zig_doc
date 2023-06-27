defmodule Zig.Doc do

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
      |> add_zig_doc_config(zig_doc_options)

    docs
    |> List.first
    |> Map.get(:docs)
    |> dbg(limit: 25)

    find_formatter(config.formatter).run(docs, config)
  end

  @doc false
  def add_zig_doc_config(docs, config, sema_module \\ Zig.Sema) do
    docs ++ Enum.map(config, &Generator.modulenode_from_config(&1, sema_module))
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
