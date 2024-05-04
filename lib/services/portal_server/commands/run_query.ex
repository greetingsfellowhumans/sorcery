defmodule Sorcery.PortalServer.Commands.RunQuery do
  @moduledoc false


  def entry(%{query: module, from: from} = msg, state) do
    %{store_adapter: store_adapter} = state.sorcery
    args = msg[:args] || %{}
    clauses = module.clauses(args)
    finds = module.finds()
    results = store_adapter.run_query(state.sorcery, clauses, finds)
    send(from, results)

    state
  end

end
