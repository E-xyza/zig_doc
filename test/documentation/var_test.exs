defmodule ZigDocTest.Documentation.ConstTest do
  use Zig.Doc.Case, async: true

  alias Zig.Doc.Sema

  test "const documentation is generated" do
    expect_sema({:ok, Sema.new(vars: [%{name: :foo, type: :i32}])})

    assert %{docs: [function]} = get_module("test/_sources/var.zig")

    assert [{:p, [], [" this is the variable foo."], %{}}] = function.doc
    assert "foo: i32" = function.signature

    assert_code(
      """
      foo :: i32
      """,
      function.specs
    )

    assert :vars = function.group
  end
end