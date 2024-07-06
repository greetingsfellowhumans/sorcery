defmodule Sorcery.PortalServer.Commands.CreatePortal do
  @moduledoc false
  alias Sorcery.SorceryDb.ReverseQuery, as: RQ
  alias Sorcery.SorceryDb.MnesiaAdapter
  alias Sorcery.StoreAdapter
  alias Sorcery.Query.Find
  alias Sorcery.PortalServer.Portal
  import Sorcery.Helpers.Maps

  defp sanitize_query_module(query, config_module) do
    Module.split(query)
    |> case do
      [_config_module, "Queries", _] -> query
      _li -> Module.concat([config_module, "Queries", query])
    end
  end


  def entry(%{portal_name: portal_name, query_module: query, child_pid: pid, args: args}, %Sorcery.PortalServer.InnerState{} = state) do
    %{store_adapter: store, config_module: config_module} = state
    query = sanitize_query_module(query, config_module)
    clauses = query.clauses(args)

    fwd_find_set = Find.build_lvar_attr_set(state.config_module, query, :forward)
    rev_find_set = Find.build_lvar_attr_set(state.config_module, query, :reverse)
    finds = Find.generate_find([fwd_find_set, rev_find_set])

    case StoreAdapter.query(store, state, clauses, finds) do
      {:ok, results} ->
        timestamp = Time.utc_now()
        schemas = config_module.config().schemas
        #pid_portal = %{pid: pid, query_module: query, args: args, portal_name: portal_name}
        portal = create_and_send_portal(pid, args, results, portal_name, query, timestamp)


        RQ.put_portal_table(portal)
        for {lvar, table} <- results.data do
          entities = parse_rev_entities(rev_find_set, lvar, table)
          RQ.repopulate_watcher_table(portal_name, lvar, pid, entities)
        end

        lvar_tks = query.raw_struct().lvar_tks
        data = Enum.reduce(results.data, %{}, fn {lvar, table}, acc ->
          tk = Enum.find_value(lvar_tks, fn {l, tk} ->
            if l == lvar, do: tk, else: nil
          end)
          Enum.reduce(table, acc, fn {id, entity}, acc ->
            update_in_p(acc, [tk, id], entity, fn old_entity ->
              Map.merge(entity, old_entity)
            end)
          end)
        end)
        MnesiaAdapter.apply_fetched(to_atom_keys(data, 1), schemas)

    end

    state
    |> Map.put(:pending_portals, [portal_name | state.pending_portals])
  end

  defp create_and_send_portal(child_pid, args, results, portal_name, query, timestamp) do
    portal = Portal.new(%{
      args: args,
      has_loaded?: false,
      known_matches: results,
      parent_pid: self(), 
      child_pid: child_pid, 
      portal_name: portal_name,
      query_module: query,
      updated_at: timestamp,
    })


    msg = %{
      command: :portal_merge,
      portal: portal,
    }
    send(portal.child_pid, {:sorcery, msg})
     
    portal
  end


  defp parse_rev_entities(rev_find_set, lvar, table) do
    rev_find = Enum.reduce(rev_find_set, [], fn {lvark, attrk}, acc ->
      if "#{lvark}" == "#{lvar}" do
        [attrk | acc]
      else
        acc
      end
    end)

    table
    |> Map.values()
    |> Enum.map(&(Map.take(&1, rev_find)))
  end

end
