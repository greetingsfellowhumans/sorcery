defmodule Sorcery.SorceryDb do
  @moduledoc false


  # {{{ SorceryDb

  # {{{ build_mnesia_table
  def build_mnesia_table(tk, schema_mod) do
    attrs = get_attrs_list(schema_mod)
    :mnesia.create_table(tk, [attributes: attrs])
  end
  defp get_attrs_list(schema_mod) do
    attrs = schema_mod.fields()
            |> Map.keys()
            |> Enum.sort()
    [:id | attrs] 
    |> Enum.uniq()
  end
  # }}}


  # {{{ parse_schema_module
  def parse_schema_module(name, root_mod) do
    [name | _] = String.split(name, ".")
    tk = String.to_atom(name)
    mod_suffix = Macro.camelize(name)

    full_mod = Module.concat([root_mod, mod_suffix])
    {tk, full_mod}
  end
  # }}}


  # {{{ apply_changes
  def apply_inserts(%{inserts: inserts}, schemas) do
    for {tk, table} <- inserts do
      attrs = get_attrs_list(schemas[tk])
      for {_id, entity} <- table do
        values = Enum.map(attrs, &(Map.get(entity, &1)))
        tup = List.to_tuple([tk | values])
        :mnesia.write(tup)
      end
    end
  end
  def apply_updates(%{updates: updates}, schemas) do
    for {tk, table} <- updates do
      attrs = get_attrs_list(schemas[tk])
      for {_id, entity} <- table do
        values = Enum.map(attrs, &(Map.get(entity, &1)))
        tup = List.to_tuple([tk | values])
        :mnesia.write(tup)
      end
    end
  end
  def apply_deletes(%{deletes: deletes}) do
    for {tk, ids} <- deletes do
      for id <- ids do
        :mnesia.delete({tk, id})
      end
    end
  end
  # }}}

  # }}}


  # {{{ use macro / GenServer

  defmacro __using__(opts) do
    quote do
      use GenServer

      # {{{ Setup
      def start_link(_state) do
        GenServer.start_link(__MODULE__, %{})
      end

      @impl true
      def init(_) do
        watchers_table = :ets.new(:sorcery_watchers, [:named_table, :duplicate_bag, :public, read_concurrency: true, write_concurrency: true])
        :mnesia.create_schema([node()])
        :mnesia.start()

        schema_files =
          unquote(opts)
          |> Keyword.get(:opts)
          |> Keyword.get(:paths)
          |> Map.get(:schemas)
          |> File.ls!()

        for filename <- schema_files do
          {tk, schema_mod} = Sorcery.SorceryDb.parse_schema_module(filename, __MODULE__.Schemas)
          Sorcery.SorceryDb.build_mnesia_table(tk, schema_mod)
        end

        {:ok, %{}}
      end
      # }}}


      # {{{ Client
      def cache_pid_entity(pid, portal, timestamp, tk, entity), do: :ets.insert(:sorcery_watchers, {pid, portal, timestamp, tk, entity})
      # @TODO unchache_pid_entity

      def run_mutation(mutation, pid_portals) do
        #dbg mutation
        schemas = __MODULE__.config().schemas
        timestamp = Time.utc_now()
        :mnesia.transaction(fn ->
          Sorcery.SorceryDb.apply_inserts(mutation, schemas)
          Sorcery.SorceryDb.apply_updates(mutation, schemas)
          Sorcery.SorceryDb.apply_deletes(mutation)
        end)

        for {pid, portal} <- pid_portals do 
          args = %{
            updated_at: timestamp,
            portal: portal
          }
         
          send(pid, {:sorcery, %{command: :rerun_queries, args: args}})
        end
      end

      # }}}


      # {{{ Server
      # }}}
      
    end
  end

  # }}}

end
