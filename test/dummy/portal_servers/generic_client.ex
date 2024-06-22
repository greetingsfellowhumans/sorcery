defmodule Src.PortalServers.GenericClient do
  use GenServer
  use Sorcery.GenServerHelpers


  @impl true
  def init(args) do
    outer_state = initialize_sorcery(%{}, %{sorcery_module: Src})
    outer_state = case args[:origin] do
      nil -> outer_state
      pid -> Map.put(outer_state, :origin, pid)
    end

    for portal_data <- Map.get(args, :portals) do
      spawn_portal(outer_state.sorcery, portal_data)
    end

    {:ok, outer_state}
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
  def handle_info({:sorcery, msg}, outer_state) do
    inner_state = Sorcery.PortalServer.handle_info(msg, outer_state.sorcery)

    case outer_state[:origin] do
      nil -> nil
      pid -> send(pid, {:received_msg, {self(), msg, outer_state.sorcery, inner_state}})
    end
    

    {:noreply, Map.put(outer_state, :sorcery, inner_state)}
  end


end


