defmodule Zig.Doc.Spec do
  @moduledoc false
  alias Zig.Doc.Sema

  @spec function_from_sema(Sema.fun()) :: Macro.t()

  def function_from_sema(fun) do
    return_type = {render_type(fun.return), [], Elixir}
    params = Enum.map(fun.params, fn type -> {render_type(type), [], Elixir} end)

    {:"::", [], [{fun.name, [], params}, return_type]}
  end

  def type_from_sema(%{name: name, type: type}) do
    {:"::", [], [{name, [], Elixir}, render_typedef(type)]}
  end

  def typefun_from_sema(fun) do
    params = Enum.map(fun.params, fn type -> {render_type(type), [], Elixir} end)
    {fun.name, [], params}
  end

  defp render_type(:erl_nif_binary), do: :"e.ErlNifBinary"
  defp render_type(:stacktrace), do: :"std.builtin.StackTrace" 

  defp render_type(type) when is_atom(type), do: type

  defp render_type(type = %struct{}) do
    case struct do
      Zig.Type.Optional ->
        if match?(%{name: "stub_erl_nif.ErlNifEnv"}, type.child) do
          :"beam.env"
        else
          :"?#{render_type(type.child)}"
        end

      Zig.Type.Struct ->
        render_struct(type)

      Zig.Type.Slice ->
        String.to_atom(type.repr)

      Zig.Type.Error ->
        :"!#{render_type(type.child)}"

      Zig.Type.Enum ->
        String.to_atom(type.name)

      Zig.Type.Pointer when type.optional ->
        :"?*#{render_type(type.child)}"

      Zig.Type.Pointer ->
        :"*#{render_type(type.child)}"

      Zig.Type.Bool ->
        :bool
    end
  end

  defp render_struct(%{name: "stub_erl_nif." <> what}), do: :"e.#{what}"
  defp render_struct(%{name: "beam.term" <> _}), do: :"beam.term"
  defp render_struct(%{name: name}), do: String.to_atom(name)

  defp wrap(name), do: {name, [], Elixir}

  defp render_typedef(:erl_nif_binary), do: wrap(:"e.ErlNifBinary")
  defp render_typedef(:stacktrace), do: wrap(:"std.builtin.StackTrace")
  defp render_typedef(type) when is_atom(type), do: wrap(type)

  defp render_typedef(type = %struct{}) do
    case {struct, type} do
      {Zig.Type.Struct, %{name: "stub_erl_nif." <> rest}} ->
        wrap(:"e.#{rest}")

      {Zig.Type.Optional, %{child: child}} ->
        wrap(:"?#{render_type(child)}")

      {Zig.Type.Struct, _} ->
        fields =
          Enum.map(type.required, &field_to_spec/1) ++ Enum.map(type.optional, &field_to_spec/1)

        {:{}, [], fields}

      {Zig.Type.Enum, _} ->
        type.tags
        |> Enum.map(fn {tag, _} -> wrap(:".#{tag}") end)
        |> Enum.reduce(&{:|, [], [&1, &2]})

      {Zig.Type.Pointer, %{child: child}} ->
        wrap(:"*#{render_type(child)}")

      _ ->
        :unknown
    end
  end

  defp field_to_spec({field_name, type}) do
    {:"::", [], [wrap(field_name), wrap(render_type(type))]}
  end
end
