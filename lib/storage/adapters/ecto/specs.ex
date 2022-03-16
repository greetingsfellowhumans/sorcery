defmodule Sorcery.Storage.Adapters.Ecto.Specs do
  use Norm
  
  def int_id(), do: spec(is_integer())
  
  def placeholder_id(), do: spec(is_binary() and fn id ->
    "$sorcery:" <> str_int = id
    String.to_integer(str_int)
  end)

  def id?(), do: one_of([int_id(), placeholder_id()])
  
  def multi_name(), do: spec(fn name ->
    case name do
      "$sorcery:" <> _ -> true
      "tk:" <> _ -> true
      _ -> false
    end
  end)

  def entity?(), do: spec(is_map())
  def tk?(), do: spec(is_atom())
  
  def table?(), do: spec(is_map() and fn {id, entity} ->
    conform!(id, id?()) and conform!(entity, entity?()) 
  end)
end
