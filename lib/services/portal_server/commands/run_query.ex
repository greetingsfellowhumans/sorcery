defmodule Sorcery.PortalServer.Commands.RunQuery do
  @moduledoc false
  alias Sorcery.StoreAdapter


  def entry(%{query: module, from: from} = msg, state) do
    %{store_adapter: store_adapter} = state.sorcery
    args = msg[:args] || %{}
    clauses = module.clauses(args)
    finds = module.finds()
    case StoreAdapter.query(store_adapter, state.sorcery, clauses, finds) do
      {:ok, results} -> send(from, {:sorcery, %{
        command: :query_response,
        data: results
      }})
      _ -> nil
    end

    state
  end

end
