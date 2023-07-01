defmodule Zig.Doc.Spec do
  alias Zig.Doc.Sema

  @spec function_from_sema(Sema.fun()) :: Macro.t()

  def function_from_sema(fun) do
    name = fun.name
    return_type = {render_type(fun.return), [], Elixir}
    params = Enum.map(fun.params, fn type -> {render_type(type), [], Elixir} end)

    {:"::", [], [{name, [], params}, return_type]}
  end

  def type_from_sema(type = %{def: defn}) when is_atom(defn) do
    {:"::", [], [{type.name, [], Elixir}, {defn, [], Elixir}]}
  end

  def type_from_sema(type = %{def: defn}) do
    struct = Enum.map(defn.fields, &{:"::", [], [{&1.name, [], Elixir}, {&1.type, [], Elixir}]})

    {:"::", [], [{type.name, [], Elixir}, {:{}, [], struct}]}
  end

  defp render_type(type) when is_atom(type), do: type

  defp render_type(type = %struct{}) do
    case struct do
      Zig.Type.Optional ->
        if match?(%{name: "stub_erl_nif.ErlNifEnv"}, type.child) do
          :"beam.env"
        else
          :"?#{render_type(type.child)}"
        end
      Zig.Type.Struct -> render_struct(type)
      Zig.Type.Slice -> String.to_atom(type.repr)
      Zig.Type.Error -> :"!#{render_type(type.child)}"
      Zig.Type.Enum -> String.to_atom(type.name)
    end
  end

  defp render_struct(%{name: "stub_erl_nif." <> what}), do: :"e.#{what}"
  defp render_struct(%{name: "beam.term" <> _}), do: :"beam.term"
  defp render_struct(%{name: name}), do: String.to_atom(name)
end
