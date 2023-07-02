defmodule ZigDocTest.Documentation.TypeDirectTest do
  use Zig.Doc.Case, async: true

  alias Zig.Doc.Sema

  test "type-level documentation is generated" do
    type = %{
      name: "foo",
      __struct__: Zig.Type.Struct,
      optional: %{baz: :i32},
      required: %{}
    }

    expect_sema({:ok, Sema.new(types: [%{name: :foo, type: type}])})

    assert %{typespecs: [type]} = get_module("test/_sources/type_direct.zig")

    assert :type == type.type

    assert [{:p, [], ["this is the foo type."], %{}} | rest] = type.doc
    assert "foo" = type.signature

    assert [
             {:h3, _, ["fields"], _},
             {:ul, _, [field], _},
             {:h3, _, ["consts"], _},
             {:ul, _, [const], _},
             {:h3, _, ["functions"], _},
             {:ul, _, [function], _}
           ] = rest

    assert {:li, _,
            [{:code, _, ["baz"], _}, ": ", {:code, _, ["i32"], _}, "\n this is the baz field."],
            _} = field

    assert {:li, _,
            [{:code, _, ["bar"], _}, ": ", {:code, _, ["i32"], _}, "\n this is the bar const."],
            _} = const

    assert {:li, _,
            [
              {:code, _, ["fn quux(v: foo) i32"], _},
              "\n this is the quux function."
            ], _} = function

    assert_code(
      """
      foo :: { baz :: i32 }
      """,
      type.spec
    )
  end
end
