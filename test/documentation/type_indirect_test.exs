defmodule ZigDocTest.Documentation.TypeIndirectTest do
  use Zig.Doc.Case, async: true

  alias Zig.Doc.Sema

  test "type-level documentation is generated" do
    type = %{
      name: "foo",
      __struct__: Zig.Type.Struct,
      optional: %{baz: :i32},
      required: %{}
    }

    expect_sema(Sema.new(types: [%{name: :foo, type: type}]))

    assert %{typespecs: [type]} = get_module("test/_sources/type_indirect.zig")

    assert :type == type.type

    assert [{:p, [], ["this is the foo type."], %{}} | _rest] = type.doc
    assert "foo" = type.signature

    assert_code(
      """
      foo :: { baz :: i32 }
      """,
      type.spec
    )
  end
end
