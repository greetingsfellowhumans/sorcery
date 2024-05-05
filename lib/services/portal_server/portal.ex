defmodule Sorcery.PortalServer.Portal do
  @moduledoc """
  A Portal represents an ongoing SrcQL Query.
  Rather than grabbing data and ending, it continues watching for changes to the results set.

  A copy of any given Portal is found in the state of two different PortalServers; the parent, and the child PortalServer.
  """
  import Sorcery.Helpers.Maps

  defstruct [
    :query_module,
    :child_pids,
    :parent_pid,
    :ref,
    #:reverse_query,
    args: %{}, # Is this even necessary? Might be useable for optimizing?
    known_matches: %{},
    fwd_find_set: MapSet.new([]),
    rev_find_set: MapSet.new([]),
  ]

  def new(body \\ %{}) do
    body = Map.put(body, :ref, make_ref())
    struct(__MODULE__, body)
  end

 
  @doc """
  When we freeze a portal, all the lvars are replaced with tablekeys (tk).
  If multiple lvars reference the same tablekey, they are merged.

  A frozen portal is no longer kept up to date. Instead, it is immutable.
  """
  def freeze(%{known_matches: matches} = portal) do
    frozen_data = Enum.reduce(matches.data, %{}, fn {lvar, table}, acc ->
      tk = matches.lvar_tks[lvar]
      Enum.reduce(table, acc, fn {id, entity}, acc ->
        update_in_p(acc, [tk, id], entity, &(Map.merge(&1, entity)))
      end)
    end)

    put_in_p(portal, [:known_matches, :data], frozen_data)
  end

end
