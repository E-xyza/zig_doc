defmodule Zig.SemaAPI do
  @type json :: nil | boolean | number | String.t | [json] | %{optional(String.t) => json}
  @callback sema(Path.t) :: json
end

Mox.defmock(Zig.Doc.Sema, for: Zig.SemaAPI)
