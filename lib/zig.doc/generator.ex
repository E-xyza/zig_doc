defmodule Zig.Doc.Generator do
  alias ExDoc.DocAST
  alias Zig.Doc.Spec
  @moduledoc false

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

  defp trim_first_space(<<32, next, rest::binary>>) when next != 32, do: <<next, rest::binary>>
  defp trim_first_space(line), do: line

  def modulenode_from_config({id, options}, exdoc_config, sema_module) do
    # options must include 'file' key
    with {:ok, file_path} <- Keyword.fetch(options, :file),
         {{:ok, file}, :read, _} <- {File.read(file_path), :read, file_path},
         {{:ok, sema}, :sema, _} <- {sema_module.run_sema(file_path), :sema, file_path} do
      parsed_document = Zig.Parser.parse(file)

      node = %ExDoc.ModuleNode{
        id: "#{id}",
        doc_line: 1,
        doc: doc_ast(parsed_document, file_path),
        language: ExDoc.Language.Elixir,
        title: "beam",
        group: :"zig code",
        module: :beam,
        docs_groups: [:Functions, :Types, :Constants, :Variables],
        type: :module,
        source_path: file_path,
        source_url: source_url(file_path, 1, exdoc_config)
      }

      Enum.reduce(
        parsed_document.code,
        node,
        &obtain_content(&1, &2, file_path, exdoc_config, sema)
      )
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

  defp obtain_content({:fn, fun = %{pub: true}, fn_parts}, acc, file_path, exdoc_config, sema) do
    name = Keyword.fetch!(fn_parts, :name)
    type = Keyword.fetch!(fn_parts, :type)
    params = Keyword.fetch!(fn_parts, :params)

    # find the function in the sema
    sema = Enum.find(sema.functions, &(&1.name == name)) || raise "#{name} function not found"

    specs =
      sema
      |> Spec.function_from_sema()
      |> List.wrap()

    param_string =
      params
      |> Enum.map(fn {var, _, type} -> "#{var}: #{render_type(type)}" end)
      |> Enum.join(", ")

    cond do
      should_ignore?(fun) ->
        acc

      match?(%{return: :type}, sema) ->
        signature = "#{name}(#{param_string})"
        function_type(acc, name, length(params), file_path, fun, signature, sema, exdoc_config)

      true ->
        signature = "#{name}(#{param_string}) #{render_type(type)}"

        function_content(
          acc,
          name,
          length(params),
          file_path,
          fun,
          signature,
          specs,
          exdoc_config
        )
    end
  end

  defp obtain_content(
         {:const, const = %{pub: true}, {name, _, assignment}},
         acc,
         file_path,
         exdoc_config,
         sema
       ) do
    # find the function in the sema

    this_func =
      Enum.find(sema.functions, &(&1.name == name))

    cond do
      should_ignore?(const) ->
        acc

      match?(%{return: :type}, this_func) ->
        param_string =
          this_func.params
          |> Enum.map(&render_type/1)
          |> Enum.join(", ")

        signature = "#{name}(#{param_string})"

        function_type(
          acc,
          name,
          length(this_func.params),
          file_path,
          const,
          signature,
          this_func,
          exdoc_config
        )

      this_func ->
        specs =
          this_func
          |> Spec.function_from_sema()
          |> List.wrap()

        param_string =
          this_func.params
          |> Enum.map(&render_type/1)
          |> Enum.join(", ")

        signature = "#{name}(#{param_string}) #{render_type(this_func.return)}"

        function_content(
          acc,
          name,
          length(this_func.params),
          file_path,
          const,
          signature,
          specs,
          exdoc_config
        )

      this_type = Enum.find(sema.types, &(&1.name == name)) ->
        name = this_type.name

        extras =
          assignment
          |> process_body
          |> markdown_from_typedef

        node = %ExDoc.TypeNode{
          type: :type,
          id: "#{name}",
          name: name,
          signature: "#{name}",
          doc: doc_ast(const, file_path, extras: extras),
          spec: Spec.type_from_sema(this_type),
          source_path: file_path,
          source_url: source_url(file_path, const.position.line, exdoc_config)
        }

        %{acc | typespecs: [node | acc.typespecs]}

      this_const = Enum.find(sema.decls, &(&1.name == name)) ->
        signature = "#{name}: #{this_const.type}"
        spec = {:"::", [], [{name, [], Elixir}, {this_const.type, [], Elixir}]}

        ## TODO: needs source_path and source_url
        node = %ExDoc.FunctionNode{
          id: "#{name}",
          name: name,
          arity: 0,
          doc: doc_ast(const, file_path),
          signature: signature,
          specs: [spec],
          group: :Constants,
          source_path: file_path,
          source_url: source_url(file_path, const.position.line, exdoc_config)
        }

        %{acc | docs: [node | acc.docs]}

      true ->
        acc
    end
  end

  defp obtain_content(
         {:var, var = %{pub: true}, {name, _type, _}},
         acc,
         file_path,
         exdoc_config,
         sema
       ) do
    # obtain type from semantic analysis
    cond do
      should_ignore?(var) ->
        acc

      this_var = Enum.find(sema.decls, &(&1.name == name)) ->
        signature = "#{name}: #{this_var.type}"

        specs = [{:"::", [], [{name, [], Elixir}, {this_var.type, [], Elixir}]}]

        annotations =
          Enum.flat_map(~w(threadlocal comptime)a, &List.wrap(if Map.get(var, &1), do: &1))

        node = %ExDoc.FunctionNode{
          id: "#{name}",
          name: name,
          arity: 0,
          doc: doc_ast(var, file_path),
          signature: signature,
          specs: specs,
          group: :Variables,
          annotations: annotations,
          source_path: file_path,
          source_url: source_url(file_path, var.position.line, exdoc_config)
        }

        %{acc | docs: [node | acc.docs]}

      true ->
        acc
    end
  end

  defp obtain_content(_, acc, _, _, _), do: acc

  defp function_content(
         module_node,
         name,
         arity,
         file_path,
         parameters,
         signature,
         specs,
         exdoc_config
       ) do
    group = function_group(parameters)

    node = %ExDoc.FunctionNode{
      id: "#{name}",
      name: name,
      arity: arity,
      doc: doc_ast(parameters, parameters),
      signature: signature,
      specs: specs,
      group: group,
      source_path: file_path,
      source_url: source_url(file_path, parameters.position.line, exdoc_config)
    }

    add_group(%{module_node | docs: [node | module_node.docs]}, group)
  end

  defp function_type(acc, name, arity, file_path, parameters, signature, sema, exdoc_config) do
    node = %ExDoc.TypeNode{
      type: :type,
      id: "#{name}",
      name: name,
      signature: signature,
      doc: doc_ast(parameters, file_path),
      arity: arity,
      spec: Spec.typefun_from_sema(sema),
      source_path: file_path,
      source_url: source_url(file_path, parameters.position.line, exdoc_config)
    }

    %{acc | typespecs: [node | acc.typespecs]}
  end

  require EEx
  file = Path.join(__DIR__, "markdown_from_typedef.md.eex")
  EEx.function_from_file(:defp, :markdown_from_typedef, file, [:assigns])

  defp render_type(type) when is_atom(type), do: to_string(type)

  defp render_type({:slice, opts, params}) do
    optional = if opts.allowzero, do: "?", else: ""
    const = if opts.const, do: "const ", else: ""

    "#{optional}[] #{const}#{render_type(params[:type])}"
  end

  defp render_type({:optional_type, {:ref, parts}}) do
    parts
    |> Enum.map(&to_string/1)
    |> Enum.join(".")
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

  defp should_ignore?(item), do: "ignore" in options(item)

  defp function_group(item) do
    topic =
      item
      |> options
      |> Enum.find_value(fn option ->
        if String.starts_with?(option, "topic:") do
          option
          |> String.replace_leading("topic:", "")
          |> String.trim()
        end
      end)

    if topic do
      :"Functions (#{topic})"
    else
      :Functions
    end
  end

  defp add_group(modulenode = %{docs_groups: groups}, group) do
    if group in groups do
      modulenode
    else
      %{modulenode | docs_groups: [group | groups]}
    end
  end

  defp options(%{doc_comment: nil}), do: []

  defp options(%{doc_comment: comment}) do
    comment
    |> String.trim()
    |> case do
      "<!--" <> rest ->
        rest
        |> String.split("-->")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))

      _ ->
        []
    end
  end

  defp source_url(file_path, line, exdoc_config) do
    exdoc_config.source_url_pattern
    |> String.replace("%{path}", file_path)
    |> String.replace("%{line}", to_string(line))
  end

  @empty_extras %{fields: [], consts: [], functions: []}
  defp process_body({:struct, _, opts}) do
    @empty_extras
    |> process_fields(Keyword.get(opts, :fields, []))
    |> process_consts(Keyword.get(opts, :decls, []))
  end

  defp process_body(_), do: @empty_extras

  defp process_fields(acc, [{:doc_comment, comment}, {field, type} | rest]) do
    process_fields(
      %{acc | fields: [%{name: field, type: type, comment: comment} | acc.fields]},
      rest
    )
  end

  defp process_fields(acc, [{field, type} | rest]) do
    process_fields(
      %{acc | fields: [%{name: field, type: type, comment: nil} | acc.fields]},
      rest
    )
  end

  defp process_fields(acc, [{:fn, %{pub: true, doc_comment: comment}, opts} | rest]) do
    params =
      opts
      |> Keyword.fetch!(:params)
      |> Enum.map(fn {name, _, type} -> %{name: name, type: type} end)

    fun = %{
      params: params,
      name: Keyword.fetch!(opts, :name),
      return: Keyword.fetch!(opts, :type),
      comment: comment
    }

    process_fields(
      %{acc | functions: [fun | acc.functions]},
      rest
    )
  end

  defp process_fields(acc, [_ | rest]), do: process_fields(acc, rest)

  defp process_fields(acc, []), do: acc

  defp process_consts(acc, decls) do
    %{
      acc
      | consts:
          Enum.flat_map(decls, fn
            {:const, %{pub: true, doc_comment: comment}, {name, type, _}} ->
              [%{name: name, type: type, comment: comment}]

            _ ->
              []
          end)
    }
  end
end
