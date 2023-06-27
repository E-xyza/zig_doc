defmodule Zig.Doc.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Mox
      import Zig.Doc.Case, only: [get_module: 1, expect_sema: 1, assert_code: 2]

      setup :set_mox_from_context
      setup :verify_on_exit!
    end
  end

  def get_module(file) do
    [module] =
      Zig.Doc.add_zig_doc_config([], [module: [file: file]], Zig.SemaMock)
    module
  end

  def expect_sema(sema) do
    Mox.expect(Zig.SemaMock, :run_sema, fn _ -> sema end)
  end

  defmacro assert_code(string, data) do
    quote do
      tgt = unquote(string)
      |> Code.format_string!
      |> IO.iodata_to_binary

      assert tgt == unquote(data)
      |> List.first
      |> Macro.to_string()
    end
  end
end
