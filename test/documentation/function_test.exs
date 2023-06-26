defmodule ZigDocTest.Documentation.ModuleTest do
  use Zig.Doc.Case, async: true

  test "function-level documentation is generated" do
    assert %{docs: [function]} =
      get_module("test/_sources/function.zig")

    assert [{:p, [], [" this is the function foo"], %{}}] = function.doc
  end
end
