defmodule Zig.SemaAPI do
  @type json :: nil | boolean | number | String.t() | [json] | %{optional(String.t()) => json}
  @callback run_sema(Path.t(), term, term) :: {:ok, json} | {:error, String.t()}
end

Mox.defmock(Zig.SemaMock, for: Zig.SemaAPI)
