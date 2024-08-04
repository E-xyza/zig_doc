defmodule ZigDocTest.Documentation.ConstFunctionTest do
  use Zig.Doc.Case, async: true

  alias Zig.Doc.Sema

  test "documentation is generated for consts that are functions" do
    expect_sema(Sema.new(functions: [%{name: :bar, return: :i32, params: [:i32]}]))

    assert %{docs: [function]} = get_module("test/_sources/const_function.zig")

    assert [{:p, [], ["this is the function bar"], %{}}] = function.doc

    # note that we lose the signature because we won't be digging too hard to find
    # the rest.

    assert "bar(i32) i32" = function.signature

    assert_code(
      """
      bar(i32) :: i32
      """,
      function.specs
    )

    assert :Functions = function.group
  end
end
