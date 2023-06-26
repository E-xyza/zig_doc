defmodule ZigDocTest.Documentation.ModuleTest do
  use Zig.Doc.Case, async: true

  test "module-level documentation is generated" do
    assert %{doc: [{:p, [], [" tests module-level comment content"], %{}}]} =
             get_module("test/_sources/module.zig")
  end
end
