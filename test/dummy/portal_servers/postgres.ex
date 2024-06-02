defmodule Src.PortalServers.Postgres do
  use GenServer
  use Sorcery.PortalServer
  import Sorcery.Helpers.Maps

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    state = %{} # You can still add whatever you want here

    state = Sorcery.PortalServer.add_portal_server_state(state, %{
      config_module: Src,      # This is a required key
      store_adapter: Sorcery.StoreAdapter.Ecto,

      args: %{
        repo_module: Sorcery.Repo # This is already setup under test/support/repo.ex
      }
    })
    {:ok, state}
  end

  def put_origin(), do: GenServer.call(__MODULE__, {:put_origin, self()})
  def put_origin(pid), do: GenServer.call(__MODULE__, {:put_origin, pid})

  def handle_call({:put_origin, pid}, _, state) do
    {:reply, :ok, Map.put(state, :origin, pid)}
  end
  def handle_info({:sorcery, msg}, %{sorcery: inner_state} = outer_state) do
    inner_state = Sorcery.PortalServer.handle_info(msg, inner_state)
    new_state = Map.put(outer_state, :sorcery, inner_state)

    if pid = new_state[:origin] do
      send(pid, {:postgres_received_msg, {self(), msg, outer_state, new_state}})
    end

    {:noreply, new_state}
  end


end
