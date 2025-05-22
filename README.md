# ZigDoc

Parses Zig files and transforms them into ExDoc documentation.

Note: ZigDoc is pinned to versions of ExDoc as it uses private
features in ExDoc.

This version of ZigDoc is pinned to zig 0.14.0

## Usage

You'll want to alias the `mix docs` task to ZigDoc.  In your `mix.exs` file:

```elixir
def project do
  [
    ...
    aliases: [docs: "zig_doc", ...]
    ...
  ]
end
```

## Configuration

## Installation

The package can be installed by adding `zig_doc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:zig_doc, "~> 0.5"}
  ]
end
```

Documentation can be found at <https://hexdocs.pm/zig_doc>.

