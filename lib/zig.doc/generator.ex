defmodule Zig.Doc.Generator do
  alias ExDoc.DocAST
  alias Zig.Doc.Spec

  def modulenode_from_config({id, options}, sema_module) do
    # options must include 'file' key
    with {:ok, file_path} <- Keyword.fetch(options, :file),
         {{:ok, file}, :read, _} <- {File.read(file_path), :read, file_path},
         {{:ok, sema}, :sema, _} <- {sema_module.run_sema(file_path), :sema, file_path} do

      parsed_document = Zig.Parser.parse(file)

      doc_ast = if moduledoc = parsed_document.doc_comment do
        DocAST.parse!(moduledoc, "text/markdown", [file: file_path, line: 1])
      end

      # TODO: needs source_path and source_url
      node = %ExDoc.ModuleNode{id: "#{id}", doc_line: 1, doc: doc_ast}

      Enum.reduce(parsed_document.code, node, &obtain_content(&1, &2, file_path, sema))

    else
      :error -> Mix.raise("zig doc config error: configuration for module #{id} requires a `:file` option")
      {{:error, reason}, :read, path} -> Mix.raise("zig doc error: file at `#{path}` doesn't exist")
      {{:error, reason}, :sema, path} -> Mix.raise("zig doc error: sema failed for `#{path}`")
    end
  end

  defp obtain_content({:fn, fun = %{pub: true}, fn_parts}, acc, file_path, sema) do
    doc_ast = if fndoc = fun.doc_comment do
      DocAST.parse!(fndoc, "text/markdown", [file: file_path, line: fun.position.line])
    end

    name = Keyword.fetch!(fn_parts, :name)
    type = Keyword.fetch!(fn_parts, :type)
    params = Keyword.fetch!(fn_parts, :params)

    # find the function in the sema
    specs = sema.functions
    |> Enum.find(&(&1.name == name))
    |> Spec.function_from_sema
    |> List.wrap

    param_string = params
    |> Enum.map(fn {var, _, type} -> "#{var}: #{type}" end)
    |> Enum.join(", ")

    signature = "#{name}(#{param_string}) #{type}"

    # TODO: needs source_path and source_url
    node = %ExDoc.FunctionNode{
      id: "#{name}",
      name: name,
      arity: length(params),
      doc: doc_ast,
      signature: signature,
      specs: specs
    }

    %{acc | docs: [node | acc.docs]}
  end

  defp obtain_content(_, acc, _, _), do: acc
end
