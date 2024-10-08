defmodule Sorcery.PortalServer.Portal do
  @moduledoc """
  A Portal represents an ongoing SrcQL Query.
  Rather than grabbing data and ending, it continues watching for changes to the results set.

  A copy of any given Portal is found in the state of two different PortalServers; the parent, and the child PortalServer.
  """
  import Sorcery.Helpers.Maps

  defstruct [
    :query_module,
    :updated_at,
    :portal_name,
    :child_pid,
    :parent_pid,
    args: %{},
    known_matches: %{},
    temp_data: %{},
  ]

  def new(body \\ %{}) do
    body = Map.merge(body, %{
      ref: make_ref(),
      updated_at: Time.utc_now()
    })
    struct(__MODULE__, body)
  end

  def get_in(sorcery_state, portal_name, lvar) when is_map(sorcery_state) do
    path = [:portals, portal_name, :known_matches, :data, lvar]
    temp_path = [:portals, portal_name, :temp_data, lvar]

    cond do
      has_in_p(sorcery_state, temp_path) -> get_in_p(sorcery_state, temp_path) |> Map.values()
      has_in_p(sorcery_state, path) -> get_in_p(sorcery_state, path) |> Map.values()
      true -> []
    end

  end
  def get_in(_, _, _), do: []

 
  @doc """
  When we freeze a portal, all the lvars are replaced with tablekeys (tk).
  If multiple lvars reference the same tablekey, they are merged.

  A frozen portal is no longer kept up to date. Instead, it is immutable.
  """
  def freeze(%{known_matches: matches} = portal) do
    frozen_data = Enum.reduce(matches.data, %{}, fn {lvar, table}, acc ->
      tk = matches.lvar_tks[lvar]
      acc = Map.put_new(acc, tk, %{})
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




end
