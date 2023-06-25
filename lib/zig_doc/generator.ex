defmodule ZigDoc.Generator do

  alias ExDoc.DocAST

  def modulenode_from_config({id, options}) do
    # options must include 'file' key
    with {:ok, file_path} <- Keyword.fetch(options, :file),
         {{:ok, file}, _} <- {File.read(file_path), file_path} do

      parsed_document = Zig.Parser.parse(file)

      doc_ast = if moduledoc = parsed_document.doc_comment do
        DocAST.parse!(moduledoc, "text/markdown", [file: file_path, line: 1])
      end

      # TODO: needs source_path and source_link
      %ExDoc.ModuleNode{id: "#{id}", doc_line: 1, doc: doc_ast}
    else
      :error -> Mix.raise("zig doc config error: configuration for module #{id} requires a `:file` option")
      {{:error, reason}, path} -> Mix.raise("zig doc config error: file at `#{path}` doesn't exist")
    end
  end
end
