defmodule Sorcery.Schema.Db do
  @moduledoc false

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use GenServer

      def run_mutation(pid, mutation) do
        GenServer.call(pid, {:mutation, mutation})
      end


      def start_link(state) do
        GenServer.start_link(__MODULE__, %{})
      end

      @impl true
      def init(_) do
        %{tk: tk} = __MODULE__.meta()
        table = String.to_atom("sorcery_schema_ets_#{tk}")
        db = :ets.new(table, [:named_table, :ordered_set, :protected, read_concurrency: true])
        {:ok, %{ref: db, table: table}}
      end


      @impl true
      def handle_call({:mutation, mutation}, _from, state) do
        watchers_table = :ets.new(:sorcery_watchers, [:named_table, :duplicate_bag, :public, read_concurrency: true, write_concurrency: true])
        :ets.insert(:sorcery_watchers, {self(), :get_battle, Person, 1})
        :ets.insert(:sorcery_watchers, {self(), :get_battle, Person, 2})
        :ets.lookup(:sorcery_watchers, self())
        |> dbg
        #spoof = __MODULE__.gen_one(%{id: 42, health: 20})
        #spoof2 = __MODULE__.gen_one(%{id: 200, health: 100})
        #:ets.insert(state.table, {spoof.id, spoof})
        #:ets.insert(state.table, {spoof2.id, spoof2})

        ##                 id    entity
        #match_pattern = {:"$1", :"$2"}

        ##         list all matching entities
        #results = [:"$2"]

        ## entity.health > 10
        #guards = [
        #  {:>, {:map_get, :health, :"$2"}, 10}
        #]

        #:ets.select(state.table, [{ match_pattern, guards, results }])
        :mnesia.create_schema([node()])
        :mnesia.start()
        :mnesia.create_table(Person, [attributes: [:id, :name, :job]])
        tx = fn ->
          :mnesia.write({Person, 1, "Bob", "asdf"})
          :mnesia.write({Person, 2, "Joe", "xyz"})
        end
        :mnesia.transaction(tx)
        getter = fn ->
          :mnesia.select(Person, [{{Person, :"$1", :"$2", :"$3"}, [{:<, :"$1", 3}], [:"$$"]}])
        end
        :mnesia.transaction(getter)
        |> dbg


        {:reply, :ok, state}
      end

    end
  end

end
