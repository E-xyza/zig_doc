defmodule ZigDocTest.Documentation.VarTest do
  use Zig.Doc.Case, async: true

  alias Zig.Doc.Sema

  test "var documentation is generated" do
    expect_sema({:ok, Sema.new(decls: [%{name: :foo, type: :i32}])})

    assert %{docs: [function]} = get_module("test/_sources/var.zig")

    assert [{:p, [], ["this is the variable foo."], %{}}] = function.doc
    assert "foo: i32" = function.signature

    assert_code(
      """
      foo :: i32
      """,
      function.specs
    )

    assert :Variables = function.group
  end
end
