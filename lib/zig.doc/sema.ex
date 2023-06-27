defmodule Zig.Doc.Sema do
  @type type :: atom

  @type fun :: %{
    name: atom,
    return: type,
    args: [type],
  }

  @type const :: %{
    name: atom,
    type: type
  }

  @type file :: %{
    functions: [function],
    consts: [const],
    types: [type]
  }

  def new(addin \\ []) do
    Enum.into(addin, %{functions: [], consts: [], types: []})
  end
end
