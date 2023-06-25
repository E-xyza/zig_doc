defmodule ZigDocTest.Documentation.ModuleTest do
  use ExUnit.Case, async: true

  test "module-level documentation is generated" do
    assert [%{doc: [], id: "module"}] =
             ZigDoc.add_zig_doc_config([], module: [file: "test/_sources/module.zig"])
  end
end
