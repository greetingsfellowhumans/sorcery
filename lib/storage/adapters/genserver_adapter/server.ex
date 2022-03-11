defmodule Sorcery.Storage.GenserverAdapter.Server do
#  use GenServer
#  alias Sorcery.Storage.GenserverAdapter, as: Adapter
#  alias Sorcery.Storage.GenserverAdapter.Specs, as: AdapterT
#  alias Sorcery.Storage.GenserverAdapter.{CreatePortal}
#  alias Sorcery.Specs.Primative, as: T
#  alias Sorcery.Specs.Portals, as: PT
#
#  def start_link(opts) do
#    name = opts[:name] || __MODULE__
#
#    %{tables: tables, presence: presence, repo: repo, ecto: ecto} = opts
#    state = %{
#      tables: tables,
#      presence: presence,
#      repo: repo,
#      ecto: ecto,
#      db: Enum.reduce(tables, %{}, fn {tk, _}, acc -> Map.put(acc, tk, %{}) end)
#    }
#    GenServer.start_link(__MODULE__, state, name: name)
#  end
#
#  ## Callbacks
#
#  @impl true
#  def init(db) do
#    {:ok, db}
#  end
#
#  @impl true
#  def handle_call(:pop, _from, [head | tail]) do
#    {:reply, head, tail}
#  end
#
#  def handle_call(:get_state, _, state) do
#    {:reply, state, state}
#  end
#  def handle_call({:my_portals, nil}, {pid, _}, state) do
#    tks = Enum.map(state.tables, fn {tk, _} -> tk end)
#    resp = Adapter.get_presence(state.presence, tks, pid)
#    {:reply, resp, state}
#  end
#  def handle_call({:my_portals, tk}, {pid, _}, state) do
#    tks = [tk]
#    resp = Adapter.get_presence(state.presence, tks, pid)
#    {:reply, resp, state}
#  end
#
#
#  def handle_call({:create_portal, portal, opts}, {from, _}, state) do
#    portal = CreatePortal.create_portal_map(Map.merge(portal, opts), from)
#             |> CreatePortal.parse_portal(state)
#    #Task.start_link(fn ->
#    state.presence.track(from, "portals:#{portal.tk}", portal.id, portal)
#    #end)
#    {:reply, portal, state}
#  end
#
#  @impl true
#  def handle_cast({:add_entities, tk, entities}, state) do
#    new_state = Enum.reduce(entities, state, fn %{id: id} = entity, acc ->
#      e = if is_struct(entity), do: Map.from_struct(entity), else: entity
#      acc
#      |> put_in([:db, tk, id], e)
#    end)
#    {:noreply, new_state}
#  end
#
#
#  def handle_cast({:src_push, src, from, opts}, state) do
#    db = Sorcery.Storage.EctoAdapter.persist_src(src, state)
#    db = Map.merge(state.db, db)
#    state = Map.put(state, :db, db)
#
#    Task.start(fn ->
#      # The caller gets priority. Tell them to recalculate immediately.
#      send(from, "assign_portals")
#    end)
#
#    Task.start(fn ->
#      # Now we find all other presences that might care about these changes
#      portals = Sorcery.Portal.all_portals(state)
#      qmeta = Sorcery.Storage.GenserverAdapter.QueryMeta.new(state)
#      pids = Sorcery.Storage.GenserverAdapter.Query.affected_pids(portals, qmeta)
#             |> List.delete(from)
#
#      for pid <- pids do
#        send(pid, "assign_portals")
#      end
#
#    end)
#
#    {:noreply, state}
#  end
#
#
#
#  def handle_call({:view_portal, ref, tk}, from, state) do
#    %{metas: [portal]} = state.presence.get_by_key("portals:#{tk}", ref)
#    handle_call({:view_portal, portal}, from, state)
#  end
#  def handle_call({:view_portal, %{tk: _tk, guards: _guards} = portal}, from, state) do
#    table = Sorcery.Storage.GenserverAdapter.ViewPortal.view_portal(portal, state)
#    {:reply, table, state}
#  end
#
#
#  
#
end


