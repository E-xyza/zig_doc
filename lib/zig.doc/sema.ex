defmodule Zig.Doc.Sema do
  @type type :: atom

  @type fun :: %{
          name: atom,
          return: type,
          args: [type]
        }

  @type decls :: %{
          name: atom,
          type: type
        }

  @type collection :: %{
          vars: [decls],
          consts: [decls],
          functions: [fun]
        }

  @type typedef :: %{
          name: atom,
          def: atom | collection
        }

  @type file :: %{
          functions: [function],
          consts: [decls],
          vars: [decls],
          types: [typedef]
        }

  def new(addin \\ []) do
    Enum.into(addin, %{functions: [], consts: [], types: []})
  end
end
