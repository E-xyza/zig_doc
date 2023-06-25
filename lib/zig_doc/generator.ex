defmodule ZigDoc.Generator do
  def from_config({id, options}) do
    # options must include 'file' key
    with {:ok, file_path} <- Keyword.fetch(options, :file),
         {{:ok, file}, _} <- {File.read(file_path), file_path} do
      file |> dbg(limit: 25)

      %ExDoc.ModuleNode{id: "#{id}"}
    else
      :error -> Mix.raise("zig doc config error: configuration for module #{id} requires a `:file` option")
      {{:error, reason}, path} -> Mix.raise("zig doc config error: file at `#{path}` doesn't exist")
    end
  end
end
