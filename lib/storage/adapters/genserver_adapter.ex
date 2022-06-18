defmodule Sorcery.Storage.GenserverAdapter do
  use Norm
  alias Sorcery.Storage.GenserverAdapter.Specs, as: AdapterT
  alias Sorcery.Storage.GenserverAdapter.{CreatePortal}
  alias Sorcery.Specs.Primative, as: T
  alias Sorcery.Specs.Portals, as: PT
  alias Sorcery.Utils.Maps

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use GenServer

      @opts opts
      @presence_topic "portals"
      @name opts[:name] || __MODULE__

      def start_link(opts) do
        name = opts[:name] || @name

        %{tables: tables, presence: presence, repo: repo, ecto: ecto} = @opts
        state = %{
          tables: tables,
          presence: presence,
          repo: repo,
          ecto: ecto,
          db: Enum.reduce(tables, %{}, fn {tk, _}, acc -> Map.put(acc, tk, %{}) end)
        }
        GenServer.start_link(__MODULE__, state, name: name)
      end

      @contract get_state(opts :: spec(is_map())) :: AdapterT.client_state()
      def get_state(opts) do
        opts = Map.merge(@opts, opts)
        name = opts[:name] || @name
        GenServer.call(name, :get_state)
      end

      @contract add_entities(T.atom(), coll_of(T.map()), T.map()) :: :ok
      def add_entities(tk, entities, opts) do
        opts = Map.merge(@opts, opts)
        name = opts[:name] || @name
        GenServer.cast(name, {:add_entities, tk, entities})
      end

      @contract view_portal(PT.portal(), T.map()) :: T.tablemap()
      def view_portal(portal, opts) do
        opts = Map.merge(@opts, opts)
        name = opts[:name] || @name
        GenServer.call(name, {:view_portal, portal})
      end

      @contract view_portal(PT.portal_ref(), T.tk(), T.map()) :: T.tablemap()
      def view_portal(portal_ref, tk, opts) do
        opts = Map.merge(@opts, opts)
        name = opts[:name] || @name
        GenServer.call(name, {:view_portal, portal_ref, tk})
      end


      @doc ~S"""
      Legacy, socket no longer needed.
      """
      def create_portal(_socket, portal, opts), do: create_portal(portal, opts)
      def create_portal(portal, opts) do
        opts = Map.merge(opts, @opts)
        name = opts[:name] || @name
        portal = GenServer.call(name, {:create_portal, portal, opts})
        portal.id
      end


      def my_portals(), do: my_portals(nil)
      def my_portals(tk) do
        pid = self()
        GenServer.call(@name, {:my_portals, tk})
      end
      
      def get_presence(presence, tks, pid) do
        Enum.map(tks, fn tk ->
          presence.list("portals:#{tk}")
          |> Enum.reduce([], fn
            {ref, %{metas: [%{pid: ^pid}]}}, acc -> [ref | acc]
            _, acc -> acc
          end)
        end)
        |> List.flatten()
      end

      def src_push!(src, opts \\ %{}) do
        opts = Map.merge(opts, @opts)
        name = opts[:name] || @name
        #GenServer.cast(name, {:src_push, src, self(), opts})
        GenServer.call(name, {:src_push, src, self(), opts})
      end


      def unmount(pids, opts \\ %{}) do
        name = opts[:name] || @name
        GenServer.cast(name, {:unmount, pids, opts})
      end
     
      ## Callbacks

      @impl true
      def init(db) do
        {:ok, db}
      end

      @impl true
      def handle_call(:pop, _from, [head | tail]) do
        {:reply, head, tail}
      end

      def handle_call(:get_state, _, state) do
        {:reply, state, state}
      end
      def handle_call({:my_portals, nil}, {pid, _}, state) do
        tks = Enum.map(state.tables, fn {tk, _} -> tk end)
        resp = get_presence(state.presence, tks, pid)
        {:reply, resp, state}
      end
      def handle_call({:my_portals, tk}, {pid, _}, state) do
        tks = [tk]
        resp = get_presence(state.presence, tks, pid)
        {:reply, resp, state}
      end


      def handle_call({:create_portal, portal, opts}, {from, _}, state) do
        portal = CreatePortal.create_portal_map(Map.merge(portal, opts), from)
                 |> CreatePortal.parse_portal(state)
        #Task.start_link(fn ->
        state.presence.track(from, "portals:#{portal.tk}", portal.id, portal)
        #end)
        {:reply, portal, state}
      end

      @impl true
      def handle_cast({:add_entities, tk, entities}, state) do
        db = Map.get(state, :db)
        db = Map.put_new(db, tk, %{})
        new_db = Enum.reduce(entities, db, fn %{id: id} = entity, acc ->
          e = if is_struct(entity), do: Map.from_struct(entity), else: entity
          acc
          |> put_in([tk, id], e)
        end)
        new_state = Map.put(state, :db, new_db)
        {:noreply, new_state}
      end


      def handle_cast({:src_push, src, from, opts}, state) do
        db = Sorcery.Storage.EctoAdapter.persist_src(src, state)
        db = Maps.deep_merge(state.db, db)
        state = Map.put(state, :db, db)

        Task.start(fn ->
          # The caller gets priority. Tell them to recalculate immediately.
          send(from, "assign_portals")
        end)

        Task.start(fn ->
          # Now we find all other presences that might care about these changes
          portals = Sorcery.Portal.all_portals(state)
          qmeta = Sorcery.Storage.GenserverAdapter.QueryMeta.new(state)
          pids = Sorcery.Storage.GenserverAdapter.Query.affected_pids(portals, qmeta)
                 |> List.delete(from)

          for pid <- pids do
            send(pid, "assign_portals")
          end

        end)

        {:noreply, state}
      end


      def handle_cast({:unmount, pids, opts}, state) do
        new_state = Enum.reduce(pids, state, fn pid, acc ->
          Sorcery.Storage.GenserverAdapter.Unmount.unmount(pid, acc)
        end)
        {:noreply, new_state}
      end


      def handle_call({:src_push, src, from, opts}, _, state) do
        new_db = Sorcery.Storage.EctoAdapter.persist_src(src, state)
        db = Maps.deep_merge(state.db, new_db)
        state = Map.put(state, :db, db)

        Task.start(fn ->
          # The caller gets priority. Tell them to recalculate immediately.
          send(from, "assign_portals")
        end)

        Task.start(fn ->
          # Now we find all other presences that might care about these changes
          portals = Sorcery.Portal.all_portals(state)
          qmeta = Sorcery.Storage.GenserverAdapter.QueryMeta.new(state)
          pids = Sorcery.Storage.GenserverAdapter.Query.affected_pids(portals, qmeta)
                 |> List.delete(from)

          for pid <- pids do
            send(pid, "assign_portals")
          end

        end)

        {:reply, new_db, state}
      end


      def handle_call({:view_portal, ref, tk}, from, state) do
        %{metas: [portal]} = state.presence.get_by_key("portals:#{tk}", ref)
        handle_call({:view_portal, portal}, from, state)
      end
      def handle_call({:view_portal, %{tk: _tk, guards: _guards} = portal}, from, state) do
        table = Sorcery.Storage.GenserverAdapter.ViewPortal.view_portal(portal, state)
        {:reply, table, state}
      end


      

    end

  end

end
