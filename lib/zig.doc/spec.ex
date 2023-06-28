defmodule Zig.Doc.Spec do
  alias Zig.Doc.Sema

  @spec function_from_sema(Sema.fun()) :: Macro.t()

  def function_from_sema(fun) do
    name = fun.name
    return_type = {fun.return, [], Elixir}
    args = Enum.map(fun.args, fn type -> {type, [], Elixir} end)

    {:"::", [], [{name, [], args}, return_type]}
  end

  def type_from_sema(type = %{def: defn}) when is_atom(defn) do
    {:"::", [], [{type.name, [], Elixir}, {defn, [], Elixir}]}
  end

  def type_from_sema(type = %{def: defn}) do
    struct = Enum.map(defn.fields, &{:"::", [], [{&1.name, [], Elixir}, {&1.type, [], Elixir}]})

    {:"::", [], [{type.name, [], Elixir}, {:{}, [], struct}]}
  end
end
