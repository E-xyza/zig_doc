defmodule Zig.Doc.Generator do
  alias ExDoc.DocAST
  alias Zig.Doc.Spec

  def doc_ast(content, file_path, opts \\ []) do
    if document = content.doc_comment do
      # trim each line of the documentation.  This is necessary because sometimes
      # early whitespaces are inserted into the documentation, and this causes the
      # markdown parser to be unable to parse the symbols

      extras = Keyword.get(opts, :extras, nil)
      line = line_for(content)

      [document | "#{extras}"]
      |> IO.iodata_to_binary()
      |> String.split("\n")
      |> Enum.map(&trim_first_space/1)
      |> Enum.join("\n")
      |> DocAST.parse!("text/markdown", file: file_path, line: line)
    end
  end

  defp line_for(%{position: %{line: line}}), do: line
  defp line_for(_), do: 1

  defp trim_first_space(<<32, next, rest :: binary>>) when next != 32, do: <<next, rest :: binary>>
  defp trim_first_space(line), do: line

  def modulenode_from_config({id, options}, sema_module) do
    # options must include 'file' key
    with {:ok, file_path} <- Keyword.fetch(options, :file),
         {{:ok, file}, :read, _} <- {File.read(file_path), :read, file_path},
         {{:ok, sema}, :sema, _} <- {sema_module.run_sema(file_path), :sema, file_path} do
      parsed_document = Zig.Parser.parse(file)

      # TODO: needs source_path and source_url
      node = %ExDoc.ModuleNode{
        id: "#{id}",
        doc_line: 1,
        doc: doc_ast(parsed_document, file_path),
        language: ExDoc.Language.Elixir,
        title: "beam",
        group: :"zig code",
        module: :beam,
        docs_groups: [:Functions, :Types, :Constants, :Variables],
        type: :module
      }

      Enum.reduce(parsed_document.code, node, &obtain_content(&1, &2, file_path, sema))
    else
      :error ->
        Mix.raise(
          "zig doc config error: configuration for module #{id} requires a `:file` option"
        )

      {{:error, reason}, :read, path} ->
        Mix.raise("zig doc error: failure reading file at `#{path}` (#{reason})")

      {{:error, _reason}, :sema, path} ->
        Mix.raise("zig doc error: sema failed for `#{path}`")
    end
  end

  defp obtain_content({:fn, fun = %{pub: true}, fn_parts}, acc, file_path, sema) do
    name = Keyword.fetch!(fn_parts, :name)
    type = Keyword.fetch!(fn_parts, :type)
    params = Keyword.fetch!(fn_parts, :params)

    # find the function in the sema
    specs =
      sema.functions
      |> Enum.find(&(&1.name == name))
      |> Spec.function_from_sema()
      |> List.wrap()

    param_string =
      params
      |> Enum.map(fn {var, _, type} -> "#{var}: #{render_type(type)}" end)
      |> Enum.join(", ")

    signature = "#{name}(#{param_string}) #{render_type(type)}"

    # TODO: needs source_path and source_url
    node = %ExDoc.FunctionNode{
      id: "#{name}",
      name: name,
      arity: length(params),
      doc: doc_ast(fun, file_path),
      signature: signature,
      specs: specs,
      group: :Functions
    }

    %{acc | docs: [node | acc.docs]}
  end

  defp obtain_content({:const, const = %{pub: true}, {name, _, assignment}}, acc, file_path, sema) do
    # find the function in the sema

    cond do
      this_func = Enum.find(sema.functions, &(&1.name == name)) ->
        specs =
          this_func
          |> Spec.function_from_sema()
          |> List.wrap()

        param_string = this_func.params
        |> Enum.map(&render_type/1)
        |> Enum.join(", ")

        signature = "#{name}(#{param_string}) #{render_type(this_func.return)}"

        # TODO: needs source_path and source_url
        node = %ExDoc.FunctionNode{
          id: "#{name}",
          name: name,
          arity: length(this_func.params),
          doc: doc_ast(const, file_path),
          signature: signature,
          specs: specs,
          group: :Functions
        }

        %{acc | docs: [node | acc.docs]}

      this_type = Enum.find(sema.types, &(&1.name == name)) ->
        {type, extras} =
          case {this_type.def, assignment} do
            {atom, _} when is_atom(atom) ->
              {atom, nil}

            {typedef, {form, _, block}} when form in ~w(struct enum union)a ->
              md =
                block
                |> to_typedef
                |> markdown_from_typedef()

              {typedef.type, md}

            {typedef, _} ->
              {typedef.type, markdown_from_typedef(typedef)}
          end

        node = %ExDoc.TypeNode{
          type: type,
          id: "#{name}",
          name: name,
          signature: "#{name}",
          doc: doc_ast(const, file_path, extras: extras),
          spec: Spec.type_from_sema(this_type),
        }

        %{acc | typespecs: [node | acc.typespecs]}

      this_const = Enum.find(sema.consts, &(&1.name == name)) ->
        signature = "#{name}: #{this_const.type}"
        specs = {:"::", [], [{name, [], Elixir}, {this_const.type, [], Elixir}]}

        ## TODO: needs source_path and source_url
        node = %ExDoc.FunctionNode{
          id: "#{name}",
          name: name,
          arity: 0,
          doc: doc_ast(const, file_path),
          signature: signature,
          specs: specs,
          group: :Constants
        }

        %{acc | docs: [node | acc.docs]}

      true ->
        acc
    end
  end

  defp obtain_content({:var, var = %{pub: true}, {name, _type, _}}, acc, file_path, sema) do
    # obtain type from semantic analysis
    if this_var = Enum.find(sema.vars, &(&1.name == name)) do
      signature = "#{name}: #{this_var.type}"

      specs = {:"::", [], [{name, [], Elixir}, {this_var.type, [], Elixir}]}

      node = %ExDoc.FunctionNode{
        id: "#{name}",
        name: name,
        arity: 0,
        doc: doc_ast(var, file_path),
        signature: signature,
        specs: specs,
        group: :Variables
      }

      %{acc | docs: [node | acc.docs]}
    else
      acc
    end
  end

  defp obtain_content(_, acc, _, _), do: acc

  require EEx
  file = Path.join(__DIR__, "markdown_from_typedef.md.eex")
  EEx.function_from_file(:defp, :markdown_from_typedef, file, [:assigns])

  defp to_typedef(block) do
    %{functions: [], fields: [], consts: []}
    |> fields_to_parts(Keyword.fetch!(block, :fields))
    |> decls_to_parts(Keyword.fetch!(block, :decls))
  end

  defp fields_to_parts(contents, [{:doc_comment, comment}, {name, type} | rest]) do
    fields_to_parts(%{contents | fields: [%{name: name, type: type, comment: comment}]}, rest)
  end

  defp fields_to_parts(contents, [{name, type} | rest]) do
    fields_to_parts(%{contents | fields: [%{name: name, type: type}]}, rest)
  end

  defp fields_to_parts(contents, [{:fn, %{pub: true, doc_comment: comment}, fn_parts} | rest]) do
    name = Keyword.fetch!(fn_parts, :name)
    type = Keyword.fetch!(fn_parts, :type)

    params =
      fn_parts
      |> Keyword.fetch!(:params)
      |> Enum.map(fn {name, _, type} -> %{name: name, type: type} end)

    fields_to_parts(
      %{
        contents
        | functions: [
            %{name: name, return: type, params: params, comment: comment} | contents.functions
          ]
      },
      rest
    )
  end

  defp fields_to_parts(contents, [_ | rest]), do: fields_to_parts(contents, rest)

  defp fields_to_parts(contents, []), do: contents

  defp decls_to_parts(contents, [
         {:const, %{pub: true, doc_comment: comment}, {name, type, _}} | rest
       ]) do
    this_const = %{
      name: name,
      type: type,
      comment: comment
    }

    decls_to_parts(%{contents | consts: [this_const | contents.consts]}, rest)
  end

  defp decls_to_parts(contents, [_ | rest]), do: decls_to_parts(contents, rest)

  defp decls_to_parts(contents, []), do: contents

  defp render_type(type) when is_atom(type), do: to_string(type)

  defp render_type({:slice, opts, params}) do
    optional = if opts.allowzero, do: "?", else: ""
    const = if opts.const, do: "const ", else: ""

    "#{optional}[] #{const}#{render_type(params[:type])}"
  end

  defp render_type(type = %struct{}) do
    case struct do
      Zig.Type.Optional ->
        if match?(%{name: "stub_erl_nif.ErlNifEnv"}, type.child) do
          "beam.env"
        else
          "?#{render_type(type.child)}"
        end
      Zig.Type.Struct ->
        render_struct(type)
      Zig.Type.Slice ->
        type.repr
      Zig.Type.Error ->
        "!#{render_type(type.child)}"
    end
  end

  defp render_struct(%{name: "stub_erl_nif." <> what}), do: "e.#{what}"
  defp render_struct(%{name: "beam.term" <> _}), do: "beam.term"
  defp render_struct(%{name: name}), do: name
end
