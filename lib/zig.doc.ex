defmodule Zig.Doc do
  @moduledoc """
  Translates the docstrings from your Zig code into Elixir documentation.

  For instructions on how to incorporate this into an Elixir project,
  consult `Mix.Tasks.ZigDoc`

  ## Documentation forms

  Currently, Zigler recognizes four types of code segments which should be
  documented.

  - functions
  - types
  - values
  - errors

  ### Functions

  functions have the following signature:

  `pub fn <identifier>(<arguments>) <type> {`

  and may have the property of being `comptime` which is due to either the
  function being itself a `comptime` function or it having a `comptime`
  argument.

  **NB** only `pub` functions are documented in Zigler, following the Elixir
  philosophy that only public functions should be documented.

  ### Types

  types have the following signature:

  `pub const <identifier>=<value>;`

  ### Values

  values can have one of the following signatures:

  - `pub const <identifier>=<value>;`
  - `pub var <identifier>=<value>;`

  Note that the constant value form is indistinguishable from the type form
  without doing a full parse and evaluation of the Zig code.  In order to
  avoid doing this, to disambiguate between the two, you must prepend constant
  *value* docststrings with a `!value` token.

  #### Example

  ```
  /// !value
  ///
  /// a constant representing the value 47.
  pub const fortyseven = 47;
  ```

  ### Errors

  errors appear inside special [error struct](https://ziglang.org/documentation/0.6.0/#Errors)
  and should be documented at the per-value level:

  #### Example

  ```
  /// docstring for this error struct (if desired)
  pub const my_error = error {
    /// docstring for ErrorEnum1
    ErrorEnum1,

    /// docstring for ErrorEnum2
    ErrorEnum2
  }
  ```

  ## Scope

  This module will generate documentation from all Zig code that resides in the
  same code directory as the base module (or overridden directory, if applicable).
  Zig code in subdirectories will not be subjected to document generation.
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

    config.retriever |> dbg(limit: 25)

    docs =
      config.source_beam
      |> config.retriever.docs_from_dir(config)
      |> testy
      |> add_zig_doc_config(zig_doc_options)

    find_formatter(config.formatter).run(docs, config)
  end

  defp testy(yo) do
    Enum.find(yo, fn x -> x.id == "Zig" end)
    |> dbg(limit: 25)
    yo
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
