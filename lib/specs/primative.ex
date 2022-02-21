defmodule Sorcery.Specs.Primative do
  use Norm

  def any(), do: spec(fn _ -> true end)
  def pid(), do: spec(is_pid())
  def string(), do: spec(is_binary)
  def atom(), do: spec(is_atom())
  def struct(), do: spec(is_struct())
  def map(), do: spec(is_map())
  def list(), do: spec(is_list())
  def id_int(), do: spec(is_integer() and &(&1 >= 0))
  def id(), do: one_of([ spec(is_binary()), id_int() ])

  def entity(), do: schema(%{id: id()})
  def tk(), do: atom()
  def attr(), do: atom()


  def db(), do: spec(is_map() and fn d ->
    Enum.all?(d, fn {tk, table} -> 
      is_atom(tk) and Enum.all?(table, fn {id, %{id: item_id}} ->
        (is_integer(id) or is_binary(id)) and id == item_id
      end)
    end)
  end)

  ############

  def src(), do: spec(is_struct(Sorcery.Src))
  def msg(), do: spec(is_struct(Sorcery.Msg))
  def subject(), do: spec(is_struct(Sorcery.Src.Subject))

  def watch_meta(), do: schema(%{
    pid: pid(),
    subject: subject()
  })

  def presences(), do: schema(%{"src_subjects" => schema(%{metas: coll_of(watch_meta())})})

end
