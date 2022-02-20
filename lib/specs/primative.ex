defmodule Sorcery.Specs.Primative do
  use Norm

  def any(), do: spec(fn _ -> true end)
  def atom(), do: spec(is_atom())
  def struct(), do: spec(is_struct())
  def map(), do: spec(is_map())
  def list(), do: spec(is_list())
  def id_int(), do: spec(is_integer() and &(&1 >= 0))
  def id(), do: one_of([ spec(is_binary()), id_int() ])

  def entity(), do: schema(%{id: id()})
  def tk(), do: one_of([atom(), struct()])
  def attr(), do: atom()

  def path(), do: spec(is_list() and fn [tk, i, attr] -> 
    !!conform!(tk, atom()) and !!conform!(i, id()) and !!conform!(attr, atom()) 
  end)
  def shortpath(), do: spec(is_list() and fn [tk, i] -> 
    !!conform!(tk, atom()) and !!conform!(i, id())
  end)
  def anypath(), do: spec(is_list() and fn
    [tk, i, attr] -> !!conform!(tk, atom()) and !!conform!(i, id()) and !!conform!(attr, atom()) 
    [tk, i] -> !!conform!(tk, atom()) and !!conform!(i, id())
  end)

  def lawn(), do: spec(is_map() and fn l ->
    keys = Map.keys(l)
    Enum.all?(keys, fn p -> conform!(p, path()) end)
  end)
  ############

  def ctx(), do: spec(is_struct(Ctx))
  def src(), do: spec(is_struct(Sorcery.Src))

end
