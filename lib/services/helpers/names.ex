defmodule Sorcery.Helpers.Names do
  @moduledoc false
  
  def mod_to_tk_str(mod) do
    last = "#{mod}" |> String.split(".") |> List.last()
    Macro.underscore(last)
  end
  def mod_to_tk(mod) do
    mod_to_tk_str(mod)
    |> String.to_existing_atom()
  end



end
