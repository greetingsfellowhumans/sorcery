defmodule Sorcery.Helpers.Files do
  @moduledoc false
  
  def build_modules_map(path, module_root) do
    filenames = File.ls!(path)
    Enum.reduce(filenames, %{}, fn name, acc ->
      name_root = String.split(name, ".") |> List.first()
      tk = String.to_atom(name_root)
      mod = Module.concat(module_root, Macro.camelize(name_root))
      Map.put(acc, tk, mod)
    end)
  end


end
