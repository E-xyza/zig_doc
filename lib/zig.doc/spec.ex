defmodule Zig.Doc.Spec do
  alias Zig.Doc.Sema

  @spec function_from_sema(Sema.fun) :: Macro.t

  def function_from_sema(fun) do
    name = fun.name
    return_type = {fun.return, [], Elixir}
    args = Enum.map(fun.args, fn type -> {type, [], Elixir} end)

    {:"::", [], [{name, [], args}, return_type]}
  end
end
