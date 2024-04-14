defmodule MyApp.PortalServers.Postgres do
  use GenServer


  def init(_) do
    state = %{} # You can still add whatever you want here

    state = Sorcery.PortalServer.add_portal_server_state(state, %{
      config_module: MyApp.Sorcery,      # This is a required key
      store_adapter: Sorcery.StoreAdapter.Ecto,

      args: %{
        repo_module: Sorcery.Repo # This is already setup under test/support/repo.ex
      }
    })
    {:ok, state}
  end


  def handle_info({:sorcery, msg}, state) do
    new_state = Sorcery.PortalServer.handle_info(msg, state)
    {:noreply, new_state}
  end


end
