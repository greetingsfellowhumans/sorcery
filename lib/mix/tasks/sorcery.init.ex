defmodule Mix.Tasks.Sorcery.Init do
  use Mix.Task
  

  def run(_args) do
    src_path = "lib/src/"

    Mix.Generator.create_directory(src_path)
    Mix.Generator.create_directory(Path.join(src_path, "queries"))
    Mix.Generator.create_directory(Path.join(src_path, "mutations"))
    Mix.Generator.create_directory(Path.join(src_path, "modifications"))
    Mix.Generator.create_directory(Path.join(src_path, "plugins"))
    Mix.Generator.create_directory(Path.join(src_path, "portal_servers"))
    Mix.Generator.create_directory(Path.join(src_path, "schemas"))
    Mix.Generator.create_file(src_path <> "src.ex", ~s"""
    defmodule Src do
      use Sorcery,
        debug: true
    end
    """)

    IO.puts("Created some files/directories at lib/src.")
    IO.puts("src.ex is the root source of your entire sorcery system. The high level configuration can all be modified here.")

  end

end
