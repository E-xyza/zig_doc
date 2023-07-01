defmodule ZigDocTest.Documentation.TypeDirectTest do
  use Zig.Doc.Case, async: true

  alias Zig.Doc.Sema

  test "type-level documentation is generated" do
    def = %{
      type: :struct,
      fields: [%{name: :baz, type: :i32}],
      consts: [%{name: :bar, type: :i32}],
      functions: [
        %{
          name: :quux,
          return: :i32,
          params: [:foo]
        }
      ]
    }

    expect_sema({:ok, Sema.new(types: [%{name: :foo, def: def}])})

    assert %{typespecs: [type]} = get_module("test/_sources/type_direct.zig")

    assert :struct == type.type

    assert [{:p, [], [" this is the foo type."], %{}} | rest] = type.doc
    assert "foo" = type.signature

    chunks =
      rest
      |> Enum.chunk_while(
        nil,
        fn
          {:p, [], ["  ### " <> what], _}, _ ->
            {:cont, what}

          {:ul, _, [{:li, _, code, _}], _}, what ->
            {:cont, {what, code}, what}
        end,
        fn _ -> {:cont, nil} end
      )
      |> Map.new()

    assert %{
             "consts" => [
               {:code, _, ["bar"], _},
               ": ",
               {:code, _, ["i32"], _},
               "\n this is the bar const."
             ],
             "fields" => [
               {:code, _, ["baz"], _},
               ": ",
               {:code, _, ["i32"], _},
               "\n this is the baz field."
             ],
             "functions" => [
               {:code, _, ["quux"], _},
               ": ",
               {:code, _, ["fn(v: foo) i32"], _},
               "\n this is the quux function."
             ]
           } = chunks

    assert_code(
      """
      foo :: { baz :: i32 }
      """,
      type.spec
    )
  end
end
