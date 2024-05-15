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

  def get_in(sorcery_state, portal_name, lvar) do
    parent_pid = Enum.find_value(sorcery_state.portals_to_parent, fn {pid, portals} ->
      names = Map.keys(portals)
      if portal_name in names, do: pid, else: nil
    end)
    path = [:portals_to_parent, parent_pid, portal_name, :known_matches, :data, lvar]
    if has_in_p(sorcery_state, path) do
      get_in_p(sorcery_state, path)
    else
      %{}
    end
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

  
  # {{{ all_lvars_by_tk(portal, tk)
  @doc """
  Get the list of all lvars that match a given tk
  """
  def all_lvars_by_tk(portal, tk) do
    Enum.reduce(portal.known_matches.lvar_tks, [], fn 
      {lvar, ltk}, acc when ltk == tk -> [lvar | acc]
      _, acc -> acc
    end)
  end
  # }}}


  @doc """
  This requires all placeholder values to be resolved and turned into real entities/values.
  Applies the inserts, updates, and deletes from a mutation.
  """
  def handle_mutation(portal, children_mutation) do
    case Sorcery.PortalServer.Query.run_query(portal, children_mutation) do
      {:ok, new_data} -> 
        put_in_p(portal, [:known_matches, :data], new_data)
      err -> 
        dbg err
        portal
    end
  end


end
