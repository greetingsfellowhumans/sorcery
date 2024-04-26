defmodule Sorcery.PortalServer do
  alias Sorcery.PortalServer.Commands, as: Cmd

  @doc """
  To convert any process into a PortalServer, you must follow 2 steps:
  1) Add some PortalServer configuration to the state
  2) Implement the PortalServer handlers for a handle_info function


  ```elixir
  use GenServer

  def init(_) do
    state = %{} # You can still add whatever you want here

    state = Sorcery.PortalServer.add_portal_server_state(state, %{
      config_module: MyApp.Sorcery,      # This is a required key
      store_adapter: Sorcery.StoreAdapters.Ecto,

      # This depends on the adapters you use
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
  ```
  """


  def add_portal_server_state(state, %{config_module: mod} = opts) do
    state
    |> Map.put(:sorcery, opts)
    |> put_in([:sorcery, :portals_to_parent], %{})
    |> put_in([:sorcery, :portals_to_child], %{})
  end
   

  def handle_info(%{command: :run_query} = msg, state), do: Cmd.RunQuery.entry(msg, state)
  def handle_info(%{command: :run_mutation} = msg, state), do: Cmd.RunMutation.entry(msg, state)
  def handle_info(%{command: :spawn_portal} = msg, state), do: Cmd.SpawnPortal.entry(msg, state)
  def handle_info(%{command: :receive_portal} = msg, state), do: Cmd.ReceivePortal.entry(msg, state)

end
