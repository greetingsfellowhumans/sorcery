defmodule Sorcery.PortalServer.Commands.RunQuery do


  def entry(%{query: module, from: from} = msg, state) do
    %{store_adapter: store_adapter} = state.sorcery
    args = msg[:args] || %{}
    results = store_adapter.run_query(state.sorcery, module, args)
    send(from, results)
  end

end
