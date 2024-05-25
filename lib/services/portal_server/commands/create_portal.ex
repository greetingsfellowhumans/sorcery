defmodule Sorcery.PortalServer.Commands.CreatePortal do
  @moduledoc false
  alias Sorcery.PortalServer.Commands.CreatePortal
  alias Sorcery.SorceryDb.ReverseQuery, as: RQ
  alias Sorcery.SorceryDb.MnesiaAdapter
  alias Sorcery.StoreAdapter
  alias Sorcery.Query.Find
  alias Sorcery.PortalServer.Portal
  import Sorcery.Helpers.Maps

  def entry(%{portal_name: portal_name, query_module: query, child_pid: pid, args: args}, state) do
    %{store_adapter: store, config_module: config_module} = state.sorcery
    query = Module.concat([config_module, "Queries", query])
    clauses = query.clauses(args)

    fwd_find_set = Find.build_lvar_attr_set(state.sorcery.config_module, query, :forward)
    rev_find_set = Find.build_lvar_attr_set(state.sorcery.config_module, query, :reverse)
    finds = Find.generate_find([fwd_find_set, rev_find_set])

    case StoreAdapter.query(store, state.sorcery, clauses, finds) do
      {:ok, results} ->
        timestamp = Time.utc_now()
        schemas = config_module.config().schemas
        #pid_portal = %{pid: pid, query_module: query, args: args, portal_name: portal_name}
        portal = create_and_send_portal(pid, args, results, portal_name, query, timestamp)


        #RQ.put_portal_table(portal_name, pid, query, args)
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
          Map.update(acc, tk, table, &(Map.merge(&1, table)))
        end)
        MnesiaAdapter.apply_fetched(to_atom_keys(data), schemas)

    end


    state
  end

  defp create_and_send_portal(child_pid, args, results, portal_name, query, timestamp) do
    portal = Portal.new(%{
      args: args,
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
