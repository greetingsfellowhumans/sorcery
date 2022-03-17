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
    # Sometimes due to race conditions, mod is nil so this doesn't work
    # When that happens, we need to not lose the pid from state, but save it for later.
    # Next time a process unmounts, we'll handle both of them. 
    # The cost should be negligible considering how rare it seems to be.
    mod = state[pid]
    if mod do
      orphans = Map.get(state, :orphaned, [])
      pids = [pid | orphans]
      mod.sorcery_unmount(pids)
      new_state = Map.delete(state, pid)
      {:noreply, new_state}
    else
      state =
        state
        |> Map.update(:orphaned, [pid], fn orphans -> [pid | orphans] end)
        |> Map.delete(pid)
      {:noreply, state}
    end
    
  end
end
