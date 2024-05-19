defmodule Sorcery.PortalServer.Commands.SpawnPortal do
  @moduledoc false
  alias Sorcery.PortalServer.Portal
  alias Sorcery.Query.ReverseQuery, as: RQ
  import Sorcery.Helpers.Maps
  alias Sorcery.StoreAdapter


  defp sdb_mutation(%{data: data, lvar_tks: lvar_tks}) do
    updates = Enum.reduce(data, %{}, fn {lvar, lvar_data}, acc ->
      tk = lvar_tks[lvar]
      Map.update(acc, tk, lvar_data, &(Map.merge(&1, lvar_data)))
    end)
    %{inserts: %{}, deletes: %{}, updates: updates}
  end

  def entry(%{query: module, from: from, args: args} = msg, state) do
    %{store_adapter: store_adapter} = state.sorcery
    args = msg[:args] || %{}
    clauses = module.clauses(args)


    fwd_find_set = RQ.build_lvar_attr_set(state.sorcery.config_module, module, :forward)
    rev_find_set = RQ.build_lvar_attr_set(state.sorcery.config_module, module, :reverse)
    finds = RQ.generate_find([fwd_find_set, rev_find_set])

    case StoreAdapter.query(store_adapter, state.sorcery, clauses, finds) do
      {:ok, results} ->
        # Send results to SorceryDb
        pid_portals = [%{pid: from, query_module: module, args: args, portal_name: args.portal_name}]
        mutation = sdb_mutation(results)
        state.sorcery.config_module.run_mutation(mutation, pid_portals, self())

        portal = Portal.new(%{
          query_module: module,
          child_pids: [from],
          parent_pid: self(), 
          args: args,
        })
        child_portal =
          portal
          |> Map.put(:known_matches, results)
          |> Map.put(:fwd_find_set, fwd_find_set)

        parent_portal =
          portal
          |> Map.put(:known_matches, results)
          |> Map.put(:rev_find_set, rev_find_set)
        msg = %{
          command: :spawn_portal_response,
          from: self(),
          args: Map.merge(args, %{portal: child_portal})
        }
        send(from, {:sorcery, msg})

        state
        |> put_in_p([:sorcery, :portals_to_child, from, args.portal_name], parent_portal)
    end

  end


end
