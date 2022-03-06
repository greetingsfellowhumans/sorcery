defmodule Sorcery.Specs.Primative do
  use Norm

  def any(), do: spec(fn _ -> true end)

  # Due to the difficulty of hardcoding pids in tests, we allow integers.
  def pid(), do: spec(is_pid() or is_integer())

  def string(), do: spec(is_binary)
  def bool(), do: spec(is_boolean())
  def atom(), do: spec(is_atom())
  def struct(), do: spec(is_struct())
  def map(), do: spec(is_map())
  def list(), do: spec(is_list())
  def id_int(), do: spec(is_integer() and &(&1 >= 0))
  def id(), do: one_of([ spec(is_binary()), id_int() ])

  def entity(), do: schema(%{id: id()})
  def tk(), do: atom()
  def attr(), do: atom()


  @doc """
  Map format for a list of entities of a given type.
  %{
    1 => %{id: 1, name: "asdf"},
    2 => %{id: 2, name: "qwerty"},
  }
  """
  def tablemap(), do: spec(is_map() and fn t ->
    Enum.all?(t, fn {id, %{id: entity_id}} ->
      (is_integer(id) and id == entity_id)
    end)
  end)

  @doc """
  Format for the collection of all entities
  %{
    user: %{
      1 => %{id: 1, name: "asdf"},
      2 => %{id: 2, name: "qwerty"},
    },
    comment: %{
      1 => %{id: 1, body: "asdf"},
      2 => %{id: 2, body: "qwerty"},
    },
  }
  """
  def db(), do: spec(is_map() and fn d ->
    Enum.all?(d, fn {tk, table} -> 
      is_atom(tk) and conform!(table, tablemap())
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
