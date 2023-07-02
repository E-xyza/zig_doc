defmodule Zig.Doc.Sema do
  @moduledoc false

  @type type :: atom

  @type decls :: %{
          optional(:comment) => nil | String.t(),
          name: atom,
          type: type
        }

  @type fun :: %{
          optional(:comment) => nil | String.t(),
          name: atom,
          return: type,
          params: [type | decls]
        }

  @type collection :: %{
          type: :struct | :enum | :union,
          fields: [decls],
          consts: [decls],
          functions: [fun]
        }

  @type typedef :: %{
          name: atom,
          def: atom | collection
        }

  @type file :: %{
          functions: [fun],
          decls: [decls],
          types: [typedef]
        }

  def new(addin \\ []) do
    Enum.into(addin, %{functions: [], decls: [], types: []})
  end
end
