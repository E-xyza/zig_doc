defmodule Zig.Doc.Spec do
  @spec from_sema(term) :: Macro.t
  def from_sema(sema) do

    name = :function_name_placeholder
    return_type = {:placeholder, [], Elixir}
    args = []

    args = Enum.map(args, fn type -> {type, [], Elixir} end)

    spec = {:"::", [], [{name, [], args}, return_type]}
    {:ok, spec}
  end
end
