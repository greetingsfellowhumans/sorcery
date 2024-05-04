defmodule Sorcery.StoreAdapter.Ecto do
  @moduledoc """
  This adapter requires the repo module to be passed in as args. 

  Here is an example PortalServer

  ```elixir
  defmodule MyApp.PortalServers.Postgres do
    use GenServer

    def init(_) do
      state = %{} # You can still add whatever you want here

      state = Sorcery.PortalServer.add_portal_server_state(state, %{
        config_module: MyApp.Sorcery,  # See below
        store_adapter: Sorcery.StoreAdapter.Ecto,

        args: %{
          repo_module: MyApp.Repo
        }
      })
      {:ok, state}
    end


    def handle_info({:sorcery, msg}, state) do
      new_state = Sorcery.PortalServer.handle_info(msg, state)
      {:noreply, new_state}
    end


  end

  defmodule MyApp.Sorcery do
    use Sorcery,
      debug: if Mix.env == :prod, do: false, else: true,
      paths: %{
        schemas: "lib/my_app/sorcery/schemas",
        queries: "lib/my_apop/sorcery/queries"
      }
  end

  ```

  """
  alias Sorcery.StoreAdapter.Ecto


  def run_query(portal_server_state, query_module, args) do
    Ecto.Query.run_query(portal_server_state, query_module, args)
  end

end
