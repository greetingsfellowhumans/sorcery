defmodule Sorcery.PortalServer.Commands.SpawnPortal do
  alias Sorcery.PortalServer.Portal
  alias Sorcery.Query.ReverseQuery, as: RQ
  alias Sorcery.ReturnedEntities, as: RE
  import Sorcery.Helpers.Maps


  def entry(%{query: module, from: from} = msg, state) do
    %{store_adapter: store_adapter} = state.sorcery
    args = msg[:args] || %{}
    clauses = module.clauses(args)


    fwd_find_set = RQ.build_lvar_attr_set(state.sorcery.config_module, module, :forward)
    rev_find_set = RQ.build_lvar_attr_set(state.sorcery.config_module, module, :reverse)
    finds = RQ.generate_find([fwd_find_set, rev_find_set])

    results = store_adapter.run_query(state.sorcery, clauses, finds)
    fwd_results = RE.apply_find_map(results, RQ.generate_find(fwd_find_set))
    rev_results = RE.apply_find_map(results, RQ.generate_find(rev_find_set))

    portal = Portal.new(%{
      query_module: module,
      child_pids: [from],
      parent_pid: self(), 
      args: args,
    })
    child_portal =
      portal
      |> Map.put(:known_matches, fwd_results)
      |> Map.put(:fwd_find_set, fwd_find_set)

    parent_portal =
      portal
      |> Map.put(:known_matches, rev_results)
      |> Map.put(:rev_find_set, rev_find_set)
    #results = RQ.prune_results(results, fwd_find_set)
    msg = %{
      command: :spawn_portal_response,
      from: self(),
      args: Map.merge(args, %{portal: child_portal})
    }
    send(from, {:sorcery, msg})

    state
    |> put_in_p([:sorcery, :portals_to_child, args.portal_name], parent_portal)
  end


end
