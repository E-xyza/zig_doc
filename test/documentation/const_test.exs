defmodule ZigDocTest.Documentation.ConstTest do
  use Zig.Doc.Case, async: true

  alias Zig.Doc.Sema

  test "const documentation is generated" do
    expect_sema(Sema.new(decls: [%{name: :foo, type: :i32}]))

    assert %{docs: [function]} = get_module("test/_sources/const.zig")

    assert [{:p, [], ["this is the const foo."], %{}}] = function.doc
    assert "foo: i32" = function.signature

    assert_code(
      """
      foo :: i32
      """,
      function.specs
    )

    assert :Constants = function.group
  end
end
