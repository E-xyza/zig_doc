defmodule ZigDocTest.Documentation.FunctionTest do
  use Zig.Doc.Case, async: true

  alias Zig.Doc.Sema

  test "function-level documentation is generated" do
    expect_sema({:ok, Sema.new(functions: [%{name: :foo, return: :i32, params: [:i32]}])})

    assert %{docs: [function]} = get_module("test/_sources/function.zig")

    assert [{:p, [], ["this is the function foo"], %{}}] = function.doc
    assert "foo(value: i32) i32" = function.signature

    assert_code(
      """
      foo(i32) :: i32
      """,
      function.specs
    )

    assert :Functions = function.group
  end
end
