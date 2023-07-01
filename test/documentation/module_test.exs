defmodule ZigDocTest.Documentation.ModuleTest do
  use Zig.Doc.Case, async: true

  alias Zig.Doc.Sema

  test "module-level documentation is generated" do
    expect_sema({:ok, Sema.new()})

    assert %{doc: [{:p, [], ["tests module-level comment content"], %{}}]} =
             get_module("test/_sources/module.zig")
  end
end
