defmodule Zig.Doc.Generator do
  alias ExDoc.DocAST

  def modulenode_from_config({id, options}) do
    # options must include 'file' key
    with {:ok, file_path} <- Keyword.fetch(options, :file),
         {{:ok, file}, _} <- {File.read(file_path), file_path} do

      parsed_document = Zig.Parser.parse(file)

      doc_ast = if moduledoc = parsed_document.doc_comment do
        DocAST.parse!(moduledoc, "text/markdown", [file: file_path, line: 1])
      end

      # TODO: needs source_path and source_url
      node = %ExDoc.ModuleNode{id: "#{id}", doc_line: 1, doc: doc_ast}

      Enum.reduce(parsed_document.code, node, &obtain_content(&1, &2, file_path))

    else
      :error -> Mix.raise("zig doc config error: configuration for module #{id} requires a `:file` option")
      {{:error, reason}, path} -> Mix.raise("zig doc config error: file at `#{path}` doesn't exist")
    end
  end

  defp obtain_content({:fn, fn_opts = %{pub: true}, fn_parts}, acc, file_path) do
    name = Keyword.fetch!(fn_parts, :name)

    doc_ast = if fndoc = fn_opts.doc_comment do
      DocAST.parse!(fn_opts.doc_comment, "text/markdown", [file: file_path, line: fn_opts.position.line])
    end

    params = Keyword.fetch!(fn_parts, :params)

    # TODO: needs source_path and source_url
    node = %ExDoc.FunctionNode{id: "#{name}", name: name, arity: length(params), doc: doc_ast}

    %{acc | docs: [node | acc.docs]}
  end

  defp obtain_content(_, acc, _), do: acc
end
