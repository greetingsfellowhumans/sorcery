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

  def get_in(%{has_loaded?: false}, _portal_name, _lvar), do: []
  def get_in(sorcery_state, portal_name, lvar) when is_map(sorcery_state) do
    with {:portal, portal}      when is_map(portal) <- {:portal, get_in_p(sorcery_state, [:portals, portal_name])},
         {:temp_table, table}   when is_map(table)  <- {:temp_table,  get_in_p(portal, [:temp_data, lvar])},
         {:li, li} when is_list(li)                 <- {:li, Map.values(table)} do
      li
    else
      {:portal, nil} -> 
        portal_names = Map.keys(sorcery_state.portals)
                       |> Enum.join("\n")
        raise "No portal named #{portal_name}. Available portal names:\n#{portal_names}"
      {:temp_table, _} ->
        portal = get_in_p(sorcery_state, [:portals, portal_name])
        full_data = get_in_p(portal, [:known_matches, :data]) || %{}
        cond do
          is_map(full_data[lvar]) -> Map.values(full_data[lvar])
          true -> 
            lvars = Map.keys(full_data) |> Enum.join("\n")
            raise "No lvar #{lvar} in #{portal_name}. Available lvars are:\n#{lvars}"
        end
    end
  end
  #def get_in(_, _, _), do: []

 
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
