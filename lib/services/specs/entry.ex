defmodule Sorcery.Specs do
  @moduledoc false
  use Norm

  #############################
  # Primatives
  #############################
  def bool?(), do: spec(is_boolean())
  def string?(), do: spec(is_binary())
  def atom?(), do: spec(is_atom())
  def int?(), do: spec(is_integer())
  def id?(), do: spec(is_integer() and fn id -> id > 0 end)
  def float?(), do: spec(is_float())
  def number?(), do: spec(is_float() or is_integer())
  def list?(), do: spec(is_list())
  def map?(), do: spec(is_map())
  def mapset?(), do: spec(is_struct(MapSet))
  def nil?(), do: spec(is_nil())
  def any?(), do: spec(fn _ -> true end)
  def kwli?(), do: coll_of({atom?(), any?()})
  def mod?(), do: atom?()
  def struct?(), do: spec(is_struct())
  def struct?(t), do: spec(is_struct(t))
  def function?(), do: spec(is_function())
  def naive_datetime(), do: spec(is_struct(NaiveDateTime))
  def pid?(), do: spec(is_pid())
  def tuple?(), do: spec(is_tuple())
  def ref?(), do: spec(is_reference())


  #############################
  # Sorceryisms
  #############################
  def re?(), do: struct?(Sorcery.ReturnedEntities)
  def tk?(), do: atom?()
      


end
