defmodule Sorcery.PortalServer.Commands.SpawnPortal do
  alias Sorcery.PortalServer.Portal
  alias Sorcery.Query.ReverseQuery, as: RQ


  def entry(%{query: module, from: from} = msg, state) do
    %{store_adapter: store_adapter} = state.sorcery
    args = msg[:args] || %{}
    results = store_adapter.run_query(state.sorcery, module, args)
    portal = Portal.new(%{
      query_module: module,
      child_pids: [from],
      parent_pid: self(), 
      args: args,
      fwd_find_set: RQ.build_lvar_attr_set(state.sorcery.config_module, module, :forward),
      rev_find_set: RQ.build_lvar_attr_set(state.sorcery.config_module, module, :reverse)
      #known_matches: module.known_lvars(results),
      #reverse_query: module.reverse_query(state.sorcery.config_module, args),
    })
    send(from, portal)
  end


  @doc """
  In order to have robust reverse queries, we must make sure all lvar/attr pairs are included in the query.find.
  After we store the results in the known_lvar_values, we then remove those attributes that did not exist in the user defined Query.find.
  """

end
