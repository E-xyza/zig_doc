defmodule Zig.Doc.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Mox
      import Zig.Doc.Case, only: [get_module: 1, expect_sema: 1]

      setup :set_mox_from_context
      setup :verify_on_exit!
    end
  end

  def get_module(file) do
    [module] =
      Zig.Doc.add_zig_doc_config([], [module: [file: file]], Zig.Doc.Sema)
    module
  end

  def expect_sema(sema) do
    Mox.expect(Zig.Doc.Sema, :run_sema, fn _ -> sema end)
  end
end
