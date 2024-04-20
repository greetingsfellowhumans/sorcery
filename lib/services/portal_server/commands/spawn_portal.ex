defmodule Sorcery.PortalServer.Commands.SpawnPortal do
  alias Sorcery.PortalServer.Portal
  alias Sorcery.Query.ReverseQuery, as: RQ


  def entry(%{query: module, from: from} = msg, state) do
    %{store_adapter: store_adapter} = state.sorcery
    fwd_find_set = RQ.build_lvar_attr_set(state.sorcery.config_module, module, :forward)
    rev_find_set = RQ.build_lvar_attr_set(state.sorcery.config_module, module, :reverse)

    args = msg[:args] || %{}
    clauses = module.clauses(args)

    finds = RQ.generate_find([fwd_find_set, rev_find_set])

    results = store_adapter.run_query(state.sorcery, clauses, finds)
    portal = Portal.new(%{
      query_module: module,
      child_pids: [from],
      parent_pid: self(), 
      args: args,
      fwd_find_set: fwd_find_set,
      rev_find_set: rev_find_set,
      known_matches: RQ.get_known_matches(results, rev_find_set),
      #reverse_query: module.reverse_query(state.sorcery.config_module, args),
    })
    results = RQ.prune_results(results, fwd_find_set)
    send(from, {portal, results})
  end


  @doc """
  In order to have robust reverse queries, we must make sure all lvar/attr pairs are included in the query.find.
  After we store the results in the known_lvar_values, we then remove those attributes that did not exist in the user defined Query.find.
  """

end
