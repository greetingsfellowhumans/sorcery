defmodule Src.PortalServers.GenericClient do
  use GenServer
  use Sorcery.GenServerHelpers


  @impl true
  def init(args) do
    state = initialize_sorcery(%{}, %{sorcery_module: Src})
    state = case args[:origin] do
      nil -> state
      pid -> Map.put(state, :origin, pid)
    end

    for portal_data <- Map.get(args, :portals) do
      spawn_portal(state, portal_data)
    end

    {:ok, state}
  end

  def get_state(pid), do: GenServer.call(pid, :get_state)
  def spoof(pid, cb), do: GenServer.call(pid, {:spoof, cb})

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:spoof, cb}, _from, state) do
    {:reply, cb.(), state}
  end

  @impl true
  def handle_info({:sorcery, msg}, state) do
    new_state = Sorcery.PortalServer.handle_info(msg, state)

    case state[:origin] do
      nil -> nil
      pid -> send(pid, {:received_msg, {self(), msg, state, new_state}})
    end
    

    {:noreply, new_state}
  end


end


