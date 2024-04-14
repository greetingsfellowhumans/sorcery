defmodule Sorcery.StoreAdapter.Ecto do
  alias Sorcery.StoreAdapter.Ecto


  def run_query(portal_server_state, query_module, args) do
    Ecto.Query.run_query(portal_server_state, query_module, args)
  end

end
