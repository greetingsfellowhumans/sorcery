defmodule Sorcery.StoreAdapter.InMemory do
  @moduledoc """
  This is the adapter for keeping everything in plain elixir maps. Quick and easy. Also the default mode for LiveViews. 
  ```

  """
  @behaviour Sorcery.StoreAdapter
  alias Sorcery.StoreAdapter.InMemory


  @impl true
  defdelegate run_query(portal_server_state, query_module, args), to: InMemory.Query

  @impl true
  defdelegate run_mutation(portal_server_state, mutation), to: InMemory.Mutation

end
