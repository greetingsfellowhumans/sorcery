defmodule Sorcery.StoreAdapter.Ecto do
  @moduledoc """
  This adapter requires the repo module to be passed in as args. 

  Here is an example PortalServer

  ```elixir
  defmodule Src.PortalServers.Postgres do
    use GenServer

    def init(_) do
      state = %{} # You can still add whatever you want here

      state = Sorcery.PortalServer.add_portal_server_state(state, %{
        config_module: Src,  # See below
        store_adapter: Sorcery.StoreAdapter.Ecto,

        args: %{
          repo_module: MyApp.Repo
        }
      })
      {:ok, state}
    end


    def handle_info({:sorcery, msg}, %{sorcery: inner_state} = outer_state) do
      inner_state = Sorcery.PortalServer.handle_info(msg, inner_state)
      {:noreply, Map.put(outer_state, :sorcery, inner_state)}
    end


  end
  ```

  """
  @behaviour Sorcery.StoreAdapter
  alias Sorcery.StoreAdapter.Ecto


  @impl true
  defdelegate run_query(inner_state, clauses, finds), to: Ecto.Query

  @impl true
  defdelegate run_mutation(inner_state, mutation), to: Ecto.Mutation

end
