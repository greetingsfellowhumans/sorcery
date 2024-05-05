defmodule MyApp.PortalServers.LiveView do
  use GenServer


  def init(_) do

    assigns = Sorcery.PortalServer.add_portal_server_state(%{}, %{
      config_module: MyApp.Sorcery,      # This is a required key
      store_adapter: Sorcery.StoreAdapter.InMemory,

      args: %{
        db: %{}
      }
    })

    {:ok, %{assigns: assigns}}
  end


  def handle_info({:sorcery, msg}, state) do
    assigns = Sorcery.PortalServer.handle_info(msg, state.assigns)
    {:noreply, Map.put(state, :assigns, assigns)}
  end


end
