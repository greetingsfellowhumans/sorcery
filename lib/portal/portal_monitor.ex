defmodule Sorcery.PortalMonitor do
  use GenServer

  def monitor(pid, mod) do
    GenServer.call(:portal_monitor, {:monitor, pid, mod})
  end

  def start_link(_default) do
    GenServer.start_link(__MODULE__, %{}, name: :portal_monitor)
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:monitor, pid, mod}, _, state) do
    Process.monitor(pid)
    {:reply, :ok, Map.put(state, pid, mod)}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state[pid].sorcery_unmount(pid)
    new_state = Map.delete(state, pid)
    {:noreply, new_state}
  end
end
