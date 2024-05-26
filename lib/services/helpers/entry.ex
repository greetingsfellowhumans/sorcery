defmodule Sorcery.Helpers do
  @moduledoc false


  alias Sorcery.Helpers, as: S

  defdelegate build_modules_map(path, module_root), to: S.Files
  defdelegate mod_to_tk_str(mod), to: S.Names
  defdelegate mod_to_tk(mod), to: S.Names

end
