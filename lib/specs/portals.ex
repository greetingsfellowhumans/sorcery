defmodule Sorcery.Specs.Portals do
  use Norm
  alias Sorcery.Specs.Primative, as: T


  def portal_ref(), do: spec(fn s ->
    case String.split(s, ":") do
      [_unique_ref, _tk] -> true
      _ -> false
    end
  end)


  def fun_atom(), do: T.atom()


  def guard(), do: one_of([
    {fun_atom(), T.attr(), {:in, T.attr(), portal_ref()}},
    {fun_atom(), T.attr(), {:in, T.attr(), coll_of(T.map())}},
    {fun_atom(), T.attr(), T.any()}
  ])


  def portal(), do: schema(%{
    id: T.id,
    pid: T.pid(),
    tk: T.tk(),
    ids: coll_of(T.id),
    guards: coll_of(guard())
  })


  def portal_presence(), do: schema(%{pid: T.pid(), portals: coll_of(portal())})


  # %{tk_or_name => %{id => entity}}
  def assigned_portal(), do: T.db()



end
