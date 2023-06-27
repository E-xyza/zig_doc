defmodule Zig.SemaAPI do
  @type json :: nil | boolean | number | String.t | [json] | %{optional(String.t) => json}
  @callback run_sema(Path.t) :: {:ok, json} | {:error, String.t}
end

Mox.defmock(Zig.SemaMock, for: Zig.SemaAPI)
