defmodule ZigDocTest.Documentation.TypeBasicTest do
  use Zig.Doc.Case, async: true

  alias Zig.Doc.Sema

  test "type-level documentation is generated" do
    expect_sema({:ok, Sema.new(types: [%{name: :foo, def: :i32}])})

    assert %{typespecs: [type]} = get_module("test/_sources/type_basic.zig")

    assert [{:p, [], ["this is the foo type."], %{}}] = type.doc
    assert "foo" = type.signature

    assert_code(
      """
      foo :: i32
      """,
      type.spec
    )
  end
end
