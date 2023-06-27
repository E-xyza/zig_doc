defmodule ZigDocTest.Documentation.ModuleTest do
  use Zig.Doc.Case, async: true

  test "function-level documentation is generated" do
    expect_sema({:ok, %{}})

    assert %{docs: [function]} =
      get_module("test/_sources/function.zig")

    assert [{:p, [], [" this is the function foo"], %{}}] = function.doc
    assert "foo(value: i32) i32" = function.signature
  end
end
